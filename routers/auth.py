from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import timedelta
from models.database import get_db, User, Passenger, Driver
from models.schemas import (
    PassengerCreate, PassengerResponse, DriverCreate, DriverResponse,
    LoginRequest, Token, StandardResponse
)
from utils.auth import (
    authenticate_user, create_access_token, get_password_hash,
    ACCESS_TOKEN_EXPIRE_MINUTES
)

router = APIRouter(prefix="/auth", tags=["authentication"])

# Passenger Registration
@router.post("/passenger/register", response_model=StandardResponse)
async def register_passenger(
    passenger_data: PassengerCreate,
    db: Session = Depends(get_db)
):
    """Register a new passenger."""
    
    # Check if user already exists
    existing_user = db.query(User).filter(User.phone == passenger_data.phone).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phone number already registered"
        )
    
    # Check if email already exists
    if passenger_data.email:
        existing_email = db.query(User).filter(User.email == passenger_data.email).first()
        if existing_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
    
    try:
        # Create user
        hashed_password = get_password_hash(passenger_data.password)
        user = User(
            phone=passenger_data.phone,
            password=hashed_password,
            full_name=passenger_data.full_name,
            email=passenger_data.email,
            user_type="passenger"
        )
        db.add(user)
        db.flush()  # Get the user ID
        
        # Create passenger profile
        passenger = Passenger(
            user_id=user.id,
            phone=passenger_data.phone,
            full_name=passenger_data.full_name,
            email=passenger_data.email
        )
        db.add(passenger)
        db.commit()
        
        # Create access token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": str(user.id), "user_type": "passenger"},
            expires_delta=access_token_expires
        )
        
        return StandardResponse(
            success=True,
            message="Passenger registered successfully",
            data={
                "access_token": access_token,
                "token_type": "bearer",
                "user_data": {
                    "id": passenger.id,
                    "phone": passenger.phone,
                    "full_name": passenger.full_name,
                    "email": passenger.email,
                    "user_type": "passenger"
                }
            }
        )
    
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Registration failed: {str(e)}"
        )

# Passenger Login
@router.post("/passenger/login", response_model=StandardResponse)
async def login_passenger(
    login_data: LoginRequest,
    db: Session = Depends(get_db)
):
    """Authenticate passenger."""
    
    user = authenticate_user(db, login_data.phone, login_data.password, "passenger")
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid phone number or password"
        )
    
    # Get passenger profile
    passenger = db.query(Passenger).filter(
        Passenger.user_id == user.id,
        Passenger.is_active == True
    ).first()
    
    if not passenger:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Passenger profile not found"
        )
    
    # Create access token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id), "user_type": "passenger"},
        expires_delta=access_token_expires
    )
    
    return StandardResponse(
        success=True,
        message="Login successful",
        data={
            "access_token": access_token,
            "token_type": "bearer",
            "user_data": {
                "id": passenger.id,
                "phone": passenger.phone,
                "full_name": passenger.full_name,
                "email": passenger.email,
                "user_type": "passenger"
            }
        }
    )

# Driver Registration
@router.post("/driver/register", response_model=StandardResponse)
async def register_driver(
    driver_data: DriverCreate,
    db: Session = Depends(get_db)
):
    """Register a new driver."""
    
    # Check if user already exists
    existing_user = db.query(User).filter(User.phone == driver_data.phone).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phone number already registered"
        )
    
    # Check if email already exists
    if driver_data.email:
        existing_email = db.query(User).filter(User.email == driver_data.email).first()
        if existing_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
    
    # Check if license number already exists
    if driver_data.license_number:
        existing_license = db.query(Driver).filter(
            Driver.license_number == driver_data.license_number
        ).first()
        if existing_license:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="License number already registered"
            )
    
    try:
        # Create user
        hashed_password = get_password_hash(driver_data.password)
        user = User(
            phone=driver_data.phone,
            password=hashed_password,
            full_name=driver_data.full_name,
            email=driver_data.email,
            user_type="driver"
        )
        db.add(user)
        db.flush()  # Get the user ID
        
        # Create driver profile
        driver = Driver(
            user_id=user.id,
            phone=driver_data.phone,
            full_name=driver_data.full_name,
            email=driver_data.email,
            license_number=driver_data.license_number,
            vehicle_number=driver_data.vehicle_number,
            vehicle_type=driver_data.vehicle_type
        )
        db.add(driver)
        db.commit()
        
        # Create access token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": str(user.id), "user_type": "driver"},
            expires_delta=access_token_expires
        )
        
        return StandardResponse(
            success=True,
            message="Driver registered successfully",
            data={
                "access_token": access_token,
                "token_type": "bearer",
                "user_data": {
                    "id": driver.id,
                    "phone": driver.phone,
                    "full_name": driver.full_name,
                    "email": driver.email,
                    "license_number": driver.license_number,
                    "vehicle_number": driver.vehicle_number,
                    "vehicle_type": driver.vehicle_type,
                    "is_online": driver.is_online,
                    "is_verified": driver.is_verified,
                    "user_type": "driver"
                }
            }
        )
    
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Registration failed: {str(e)}"
        )

# Driver Login
@router.post("/driver/login", response_model=StandardResponse)
async def login_driver(
    login_data: LoginRequest,
    db: Session = Depends(get_db)
):
    """Authenticate driver."""
    
    user = authenticate_user(db, login_data.phone, login_data.password, "driver")
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid phone number or password"
        )
    
    # Get driver profile
    driver = db.query(Driver).filter(
        Driver.user_id == user.id,
        Driver.is_active == True
    ).first()
    
    if not driver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver profile not found"
        )
    
    # Create access token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id), "user_type": "driver"},
        expires_delta=access_token_expires
    )
    
    return StandardResponse(
        success=True,
        message="Login successful",
        data={
            "access_token": access_token,
            "token_type": "bearer",
            "user_data": {
                "id": driver.id,
                "phone": driver.phone,
                "full_name": driver.full_name,
                "email": driver.email,
                "license_number": driver.license_number,
                "vehicle_number": driver.vehicle_number,
                "vehicle_type": driver.vehicle_type,
                "is_online": driver.is_online,
                "is_verified": driver.is_verified,
                "user_type": "driver"
            }
        }
    )
