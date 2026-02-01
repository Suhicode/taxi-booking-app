from fastapi import APIRouter, Depends, HTTPException, status, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
from sqlalchemy import and_
from datetime import datetime
from typing import List, Dict
import json
import math

from models.database import get_db, Ride, Driver, Passenger
from models.schemas import RideCreate, RideResponse, RideAccept, RideComplete, StandardResponse
from utils.auth import get_current_passenger, get_current_driver

router = APIRouter(prefix="/rides", tags=["rides"])

# WebSocket connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
        self.driver_connections: Dict[int, WebSocket] = {}
        self.passenger_connections: Dict[int, WebSocket] = {}

    async def connect(self, websocket: WebSocket, connection_id: str, user_type: str, user_id: int):
        await websocket.accept()
        self.active_connections[connection_id] = websocket
        
        if user_type == "driver":
            self.driver_connections[user_id] = websocket
        elif user_type == "passenger":
            self.passenger_connections[user_id] = websocket

    def disconnect(self, connection_id: str, user_type: str, user_id: int):
        if connection_id in self.active_connections:
            del self.active_connections[connection_id]
        
        if user_type == "driver" and user_id in self.driver_connections:
            del self.driver_connections[user_id]
        elif user_type == "passenger" and user_id in self.passenger_connections:
            del self.passenger_connections[user_id]

    async def send_to_driver(self, driver_id: int, message: dict):
        if driver_id in self.driver_connections:
            websocket = self.driver_connections[driver_id]
            await websocket.send_text(json.dumps(message))

    async def send_to_passenger(self, passenger_id: int, message: dict):
        if passenger_id in self.passenger_connections:
            websocket = self.passenger_connections[passenger_id]
            await websocket.send_text(json.dumps(message))

    async def broadcast_to_drivers(self, message: dict, driver_ids: List[int] = None):
        if driver_ids:
            for driver_id in driver_ids:
                await self.send_to_driver(driver_id, message)
        else:
            for driver_id, websocket in self.driver_connections.items():
                await websocket.send_text(json.dumps(message))

manager = ConnectionManager()

def calculate_distance(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Calculate distance between two coordinates in kilometers."""
    if lat1 is None or lng1 is None or lat2 is None or lng2 is None:
        return float('inf')
    
    # Convert to radians
    lat1, lng1, lat2, lng2 = map(math.radians, [lat1, lng1, lat2, lng2])
    
    # Haversine formula
    dlat = lat2 - lat1
    dlng = lng2 - lng1
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlng/2)**2
    c = 2 * math.asin(math.sqrt(a))
    
    # Earth's radius in kilometers
    r = 6371
    return c * r

def find_nearby_drivers(db: Session, pickup_lat: float, pickup_lng: float, radius_km: float = 10.0) -> List[Driver]:
    """Find nearby online drivers within radius."""
    drivers = db.query(Driver).filter(
        and_(
            Driver.is_online == True,
            Driver.is_verified == True,
            Driver.is_active == True,
            Driver.current_lat.isnot(None),
            Driver.current_lng.isnot(None)
        )
    ).all()
    
    nearby_drivers = []
    for driver in drivers:
        distance = calculate_distance(
            pickup_lat, pickup_lng,
            driver.current_lat, driver.current_lng
        )
        if distance <= radius_km:
            nearby_drivers.append(driver)
    
    # Sort by distance
    nearby_drivers.sort(key=lambda d: calculate_distance(
        pickup_lat, pickup_lng,
        d.current_lat, d.current_lng
    ))
    
    return nearby_drivers

@router.post("/request", response_model=StandardResponse)
async def request_ride(
    ride_data: RideCreate,
    current_passenger: Passenger = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Create a new ride request."""
    
    # Check if passenger has an active ride
    active_ride = db.query(Ride).filter(
        and_(
            Ride.passenger_id == current_passenger.id,
            Ride.status.in_(["requested", "accepted", "arrived", "started"])
        )
    ).first()
    
    if active_ride:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You already have an active ride"
        )
    
    try:
        # Create ride
        ride = Ride(
            passenger_id=current_passenger.id,
            pickup_lat=ride_data.pickup_lat,
            pickup_lng=ride_data.pickup_lng,
            pickup_address=ride_data.pickup_address,
            drop_lat=ride_data.drop_lat,
            drop_lng=ride_data.drop_lng,
            drop_address=ride_data.drop_address,
            city=ride_data.city,
            notes=ride_data.notes,
            status="requested"
        )
        
        db.add(ride)
        db.commit()
        db.refresh(ride)
        
        # Find nearby drivers
        nearby_drivers = find_nearby_drivers(
            db, ride_data.pickup_lat, ride_data.pickup_lng
        )
        
        if nearby_drivers:
            # Send ride request to nearby drivers via WebSocket
            ride_request_message = {
                "type": "ride_request",
                "ride_id": ride.id,
                "pickup_lat": ride.pickup_lat,
                "pickup_lng": ride.pickup_lng,
                "pickup_address": ride.pickup_address,
                "drop_lat": ride.drop_lat,
                "drop_lng": ride.drop_lng,
                "drop_address": ride.drop_address,
                "city": ride.city,
                "passenger": {
                    "id": current_passenger.id,
                    "full_name": current_passenger.full_name
                },
                "requested_at": ride.requested_at.isoformat()
            }
            
            driver_ids = [driver.id for driver in nearby_drivers[:5]]  # Send to top 5 nearby drivers
            await manager.broadcast_to_drivers(ride_request_message, driver_ids)
        
        return StandardResponse(
            success=True,
            message="Ride requested successfully",
            data={
                "id": ride.id,
                "status": ride.status,
                "pickup_address": ride.pickup_address,
                "drop_address": ride.drop_address,
                "city": ride.city,
                "requested_at": ride.requested_at.isoformat(),
                "nearby_drivers_count": len(nearby_drivers)
            }
        )
    
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to request ride: {str(e)}"
        )

@router.post("/{ride_id}/accept", response_model=StandardResponse)
async def accept_ride(
    ride_id: int,
    current_driver: Driver = Depends(get_current_driver),
    db: Session = Depends(get_db)
):
    """Accept a ride request."""
    
    # Get ride
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found"
        )
    
    # Check ride status
    if ride.status != "requested":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Ride cannot be accepted. Current status: {ride.status}"
        )
    
    # Check if driver is online
    if not current_driver.is_online:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Driver must be online to accept rides"
        )
    
    try:
        # Update ride
        ride.driver_id = current_driver.id
        ride.status = "accepted"
        ride.accepted_at = datetime.utcnow()
        
        db.commit()
        
        # Notify passenger via WebSocket
        driver_assigned_message = {
            "type": "driver_assigned",
            "ride_id": ride.id,
            "driver": {
                "id": current_driver.id,
                "full_name": current_driver.full_name,
                "phone": current_driver.phone,
                "vehicle_number": current_driver.vehicle_number,
                "vehicle_type": current_driver.vehicle_type,
                "current_lat": current_driver.current_lat,
                "current_lng": current_driver.current_lng
            },
            "accepted_at": ride.accepted_at.isoformat()
        }
        
        await manager.send_to_passenger(ride.passenger_id, driver_assigned_message)
        
        # Notify other drivers that ride was taken
        ride_taken_message = {
            "type": "ride_taken",
            "ride_id": ride.id
        }
        
        nearby_drivers = find_nearby_drivers(
            db, ride.pickup_lat, ride.pickup_lng
        )
        other_driver_ids = [d.id for d in nearby_drivers if d.id != current_driver.id]
        await manager.broadcast_to_drivers(ride_taken_message, other_driver_ids)
        
        return StandardResponse(
            success=True,
            message="Ride accepted successfully",
            data={
                "ride_id": ride.id,
                "status": ride.status,
                "accepted_at": ride.accepted_at.isoformat(),
                "passenger": {
                    "id": ride.passenger.id,
                    "full_name": ride.passenger.full_name,
                    "phone": ride.passenger.phone
                }
            }
        )
    
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to accept ride: {str(e)}"
        )

@router.post("/{ride_id}/complete", response_model=StandardResponse)
async def complete_ride(
    ride_id: int,
    ride_complete: RideComplete,
    current_driver: Driver = Depends(get_current_driver),
    db: Session = Depends(get_db)
):
    """Complete a ride."""
    
    # Get ride
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found"
        )
    
    # Check if ride belongs to current driver
    if ride.driver_id != current_driver.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to complete this ride"
        )
    
    # Check ride status
    if ride.status != "started":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Ride cannot be completed. Current status: {ride.status}"
        )
    
    try:
        # Update ride
        ride.status = "completed"
        ride.completed_at = datetime.utcnow()
        
        if ride_complete.final_fare is not None:
            ride.fare = ride_complete.final_fare
        if ride_complete.duration_minutes is not None:
            ride.duration_minutes = ride_complete.duration_minutes
        
        # Calculate fare if not provided (simple calculation)
        if ride.fare is None:
            # Base fare + distance charge
            base_fare = 50.0  # Base fare
            distance = calculate_distance(
                ride.pickup_lat, ride.pickup_lng,
                ride.drop_lat, ride.drop_lng
            )
            ride.fare = base_fare + (distance * 20)  # 20 per km
            ride.distance_km = distance
        
        db.commit()
        
        # Notify passenger via WebSocket
        ride_completed_message = {
            "type": "ride_completed",
            "ride_id": ride.id,
            "final_fare": ride.fare,
            "duration_minutes": ride.duration_minutes,
            "completed_at": ride.completed_at.isoformat()
        }
        
        await manager.send_to_passenger(ride.passenger_id, ride_completed_message)
        
        return StandardResponse(
            success=True,
            message="Ride completed successfully",
            data={
                "ride_id": ride.id,
                "status": ride.status,
                "fare": ride.fare,
                "duration_minutes": ride.duration_minutes,
                "completed_at": ride.completed_at.isoformat()
            }
        )
    
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to complete ride: {str(e)}"
        )

@router.get("/{ride_id}", response_model=StandardResponse)
async def get_ride_details(
    ride_id: int,
    db: Session = Depends(get_db)
):
    """Get ride details by ID."""
    
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found"
        )
    
    ride_data = {
        "id": ride.id,
        "pickup_lat": ride.pickup_lat,
        "pickup_lng": ride.pickup_lng,
        "pickup_address": ride.pickup_address,
        "drop_lat": ride.drop_lat,
        "drop_lng": ride.drop_lng,
        "drop_address": ride.drop_address,
        "city": ride.city,
        "status": ride.status,
        "fare": ride.fare,
        "distance_km": ride.distance_km,
        "duration_minutes": ride.duration_minutes,
        "requested_at": ride.requested_at.isoformat(),
        "accepted_at": ride.accepted_at.isoformat() if ride.accepted_at else None,
        "arrived_at": ride.arrived_at.isoformat() if ride.arrived_at else None,
        "started_at": ride.started_at.isoformat() if ride.started_at else None,
        "completed_at": ride.completed_at.isoformat() if ride.completed_at else None,
        "cancelled_at": ride.cancelled_at.isoformat() if ride.cancelled_at else None,
        "payment_status": ride.payment_status,
        "notes": ride.notes
    }
    
    # Add passenger info
    if ride.passenger:
        ride_data["passenger"] = {
            "id": ride.passenger.id,
            "full_name": ride.passenger.full_name,
            "phone": ride.passenger.phone
        }
    
    # Add driver info if assigned
    if ride.driver:
        ride_data["driver"] = {
            "id": ride.driver.id,
            "full_name": ride.driver.full_name,
            "phone": ride.driver.phone,
            "vehicle_number": ride.driver.vehicle_number,
            "vehicle_type": ride.driver.vehicle_type,
            "current_lat": ride.driver.current_lat,
            "current_lng": ride.driver.current_lng
        }
    
    return StandardResponse(
        success=True,
        message="Ride details retrieved successfully",
        data=ride_data
    )

# WebSocket endpoint for drivers
@router.websocket("/ws/driver/{driver_id}")
async def websocket_driver_endpoint(websocket: WebSocket, driver_id: int):
    connection_id = f"driver_{driver_id}"
    await manager.connect(websocket, connection_id, "driver", driver_id)
    
    try:
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # Handle different message types from driver
            if message.get("type") == "location_update":
                # Update driver location in database
                # This would require a database session, which is complex in WebSocket
                # For now, just broadcast to passenger if driver has active ride
                pass
            
            elif message.get("type") == "accept_ride":
                # Handle ride acceptance via WebSocket
                ride_id = message.get("ride_id")
                # This would call the accept_ride function
                pass
            
            elif message.get("type") == "reject_ride":
                # Handle ride rejection via WebSocket
                ride_id = message.get("ride_id")
                # Could broadcast to other drivers
                pass
    
    except WebSocketDisconnect:
        manager.disconnect(connection_id, "driver", driver_id)

# WebSocket endpoint for passengers
@router.websocket("/ws/passenger/{passenger_id}")
async def websocket_passenger_endpoint(websocket: WebSocket, passenger_id: int):
    connection_id = f"passenger_{passenger_id}"
    await manager.connect(websocket, connection_id, "passenger", passenger_id)
    
    try:
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # Handle different message types from passenger
            if message.get("type") == "cancel_ride":
                # Handle ride cancellation
                ride_id = message.get("ride_id")
                # This would update ride status and notify driver
                pass
    
    except WebSocketDisconnect:
        manager.disconnect(connection_id, "passenger", passenger_id)

# Export connection manager for use in other modules
connection_manager = manager
