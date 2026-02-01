from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from models.database import get_db, Passenger
from models.schemas import PassengerResponse, StandardResponse
from utils.auth import get_current_passenger

router = APIRouter(prefix="/passengers", tags=["passengers"])

@router.get("/profile", response_model=StandardResponse)
async def get_passenger_profile(
    current_passenger: Passenger = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Get current passenger profile."""
    
    return StandardResponse(
        success=True,
        message="Profile retrieved successfully",
        data={
            "id": current_passenger.id,
            "phone": current_passenger.phone,
            "full_name": current_passenger.full_name,
            "email": current_passenger.email,
            "is_active": current_passenger.is_active,
            "created_at": current_passenger.created_at.isoformat()
        }
    )

@router.get("/active-rides", response_model=StandardResponse)
async def get_active_rides(
    current_passenger: Passenger = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Get active rides for current passenger."""
    
    from models.database import Ride
    
    active_rides = db.query(Ride).filter(
        Ride.passenger_id == current_passenger.id,
        Ride.status.in_(["requested", "accepted", "arrived", "started"])
    ).order_by(Ride.requested_at.desc()).all()
    
    rides_data = []
    for ride in active_rides:
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
        
        rides_data.append(ride_data)
    
    return StandardResponse(
        success=True,
        message="Active rides retrieved successfully",
        data={"active_rides": rides_data}
    )

@router.get("/rides/history", response_model=StandardResponse)
async def get_ride_history(
    current_passenger: Passenger = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Get ride history for current passenger."""
    
    from models.database import Ride
    
    rides = db.query(Ride).filter(
        Ride.passenger_id == current_passenger.id,
        Ride.status.in_(["completed", "cancelled"])
    ).order_by(Ride.requested_at.desc()).limit(50).all()
    
    rides_data = []
    for ride in rides:
        ride_data = {
            "id": ride.id,
            "pickup_address": ride.pickup_address,
            "drop_address": ride.drop_address,
            "city": ride.city,
            "status": ride.status,
            "fare": ride.fare,
            "distance_km": ride.distance_km,
            "duration_minutes": ride.duration_minutes,
            "requested_at": ride.requested_at.isoformat(),
            "completed_at": ride.completed_at.isoformat() if ride.completed_at else None,
            "cancelled_at": ride.cancelled_at.isoformat() if ride.cancelled_at else None,
            "payment_status": ride.payment_status
        }
        
        # Add driver info if available
        if ride.driver:
            ride_data["driver"] = {
                "full_name": ride.driver.full_name,
                "vehicle_number": ride.driver.vehicle_number,
                "vehicle_type": ride.driver.vehicle_type
            }
        
        rides_data.append(ride_data)
    
    return StandardResponse(
        success=True,
        message="Ride history retrieved successfully",
        data={"rides": rides_data}
    )
