from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime
from models.database import get_db, Driver, Ride
from models.schemas import DriverResponse, DriverLocationUpdate, DriverStatusUpdate, StandardResponse
from utils.auth import get_current_driver

router = APIRouter(prefix="/drivers", tags=["drivers"])

@router.get("/profile", response_model=StandardResponse)
async def get_driver_profile(
    current_driver: Driver = Depends(get_current_driver),
    db: Session = Depends(get_db)
):
    """Get current driver profile."""
    
    return StandardResponse(
        success=True,
        message="Profile retrieved successfully",
        data={
            "id": current_driver.id,
            "phone": current_driver.phone,
            "full_name": current_driver.full_name,
            "email": current_driver.email,
            "license_number": current_driver.license_number,
            "vehicle_number": current_driver.vehicle_number,
            "vehicle_type": current_driver.vehicle_type,
            "is_online": current_driver.is_online,
            "is_verified": current_driver.is_verified,
            "current_lat": current_driver.current_lat,
            "current_lng": current_driver.current_lng,
            "last_location_update": current_driver.last_location_update.isoformat() if current_driver.last_location_update else None,
            "is_active": current_driver.is_active,
            "created_at": current_driver.created_at.isoformat()
        }
    )

@router.put("/location", response_model=StandardResponse)
async def update_driver_location(
    location_update: DriverLocationUpdate,
    current_driver: Driver = Depends(get_current_driver),
    db: Session = Depends(get_db)
):
    """Update driver location."""
    
    try:
        current_driver.current_lat = location_update.lat
        current_driver.current_lng = location_update.lng
        current_driver.last_location_update = datetime.utcnow()
        
        db.commit()
        
        return StandardResponse(
            success=True,
            message="Location updated successfully"
        )
    
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update location: {str(e)}"
        )

@router.put("/status", response_model=StandardResponse)
async def update_driver_status(
    status_update: DriverStatusUpdate,
    current_driver: Driver = Depends(get_current_driver),
    db: Session = Depends(get_db)
):
    """Update driver online/offline status."""
    
    try:
        current_driver.is_online = status_update.is_online
        current_driver.updated_at = datetime.utcnow()
        
        # If going offline, clear location
        if not status_update.is_online:
            current_driver.current_lat = None
            current_driver.current_lng = None
            current_driver.last_location_update = None
        
        db.commit()
        
        status_text = "online" if status_update.is_online else "offline"
        return StandardResponse(
            success=True,
            message=f"Driver status updated to {status_text}"
        )
    
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update status: {str(e)}"
        )

@router.get("/rides", response_model=StandardResponse)
async def get_driver_rides(
    current_driver: Driver = Depends(get_current_driver),
    db: Session = Depends(get_db)
):
    """Get rides for current driver."""
    
    rides = db.query(Ride).filter(
        Ride.driver_id == current_driver.id
    ).order_by(Ride.requested_at.desc()).limit(50).all()
    
    rides_data = []
    for ride in rides:
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
        
        rides_data.append(ride_data)
    
    return StandardResponse(
        success=True,
        message="Rides retrieved successfully",
        data={"rides": rides_data}
    )

@router.get("/earnings", response_model=StandardResponse)
async def get_driver_earnings(
    current_driver: Driver = Depends(get_current_driver),
    db: Session = Depends(get_db)
):
    """Get earnings summary for current driver."""
    
    # Get completed rides
    completed_rides = db.query(Ride).filter(
        Ride.driver_id == current_driver.id,
        Ride.status == "completed",
        Ride.fare.isnot(None)
    ).all()
    
    total_rides = len(completed_rides)
    total_earnings = sum(ride.fare or 0 for ride in completed_rides)
    
    # Calculate today's earnings
    today = datetime.utcnow().date()
    today_rides = [ride for ride in completed_rides if ride.completed_at and ride.completed_at.date() == today]
    today_earnings = sum(ride.fare or 0 for ride in today_rides)
    
    return StandardResponse(
        success=True,
        message="Earnings retrieved successfully",
        data={
            "total_rides": total_rides,
            "total_earnings": total_earnings,
            "today_rides": len(today_rides),
            "today_earnings": today_earnings,
            "average_fare": total_earnings / total_rides if total_rides > 0 else 0
        }
    )
