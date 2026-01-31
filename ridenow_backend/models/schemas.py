from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

# Base schemas
class UserBase(BaseModel):
    phone: str
    full_name: str
    email: Optional[EmailStr] = None

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    id: int
    user_type: str
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

# Passenger schemas
class PassengerBase(BaseModel):
    phone: str
    full_name: str
    email: Optional[EmailStr] = None

class PassengerCreate(PassengerBase):
    password: str

class PassengerUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None

class PassengerResponse(PassengerBase):
    id: int
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

# Driver schemas
class DriverBase(BaseModel):
    phone: str
    full_name: str
    email: Optional[EmailStr] = None
    license_number: Optional[str] = None
    vehicle_number: Optional[str] = None
    vehicle_type: Optional[str] = None

class DriverCreate(DriverBase):
    password: str

class DriverUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None
    license_number: Optional[str] = None
    vehicle_number: Optional[str] = None
    vehicle_type: Optional[str] = None

class DriverResponse(DriverBase):
    id: int
    is_online: bool
    is_verified: bool
    current_lat: Optional[float] = None
    current_lng: Optional[float] = None
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class DriverLocationUpdate(BaseModel):
    lat: float
    lng: float

class DriverStatusUpdate(BaseModel):
    is_online: bool

# Ride schemas
class RideBase(BaseModel):
    pickup_lat: float
    pickup_lng: float
    pickup_address: str
    drop_lat: float
    drop_lng: float
    drop_address: str
    city: str
    notes: Optional[str] = None

class RideCreate(RideBase):
    pass

class RideResponse(RideBase):
    id: int
    passenger_id: int
    driver_id: Optional[int] = None
    status: str
    fare: Optional[float] = None
    distance_km: Optional[float] = None
    duration_minutes: Optional[float] = None
    requested_at: datetime
    accepted_at: Optional[datetime] = None
    arrived_at: Optional[datetime] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    cancelled_at: Optional[datetime] = None
    payment_status: str
    
    # Include related data
    passenger: Optional[PassengerResponse] = None
    driver: Optional[DriverResponse] = None
    
    class Config:
        from_attributes = True

class RideAccept(BaseModel):
    pass

class RideComplete(BaseModel):
    final_fare: Optional[float] = None
    duration_minutes: Optional[float] = None

# Auth schemas
class Token(BaseModel):
    access_token: str
    token_type: str
    user_data: dict

class TokenData(BaseModel):
    user_id: Optional[int] = None
    user_type: Optional[str] = None

class LoginRequest(BaseModel):
    phone: str
    password: str

# WebSocket message schemas
class WebSocketMessage(BaseModel):
    type: str
    data: dict

class RideRequestMessage(WebSocketMessage):
    type: str = "ride_request"
    data: dict

class DriverAssignedMessage(WebSocketMessage):
    type: str = "driver_assigned"
    data: dict

class DriverLocationUpdateMessage(WebSocketMessage):
    type: str = "driver_location_update"
    data: dict

class RideCompletedMessage(WebSocketMessage):
    type: str = "ride_completed"
    data: dict

class RideCancelledMessage(WebSocketMessage):
    type: str = "ride_cancelled"
    data: dict

class ErrorMessage(WebSocketMessage):
    type: str = "error"
    data: dict

# Response schemas
class StandardResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None

class ErrorResponse(BaseModel):
    detail: str
