from sqlalchemy import create_engine, Column, Integer, String, Boolean, DateTime, Float, ForeignKey, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from datetime import datetime
import os
from dotenv import load_dotenv

load_dotenv()

# Database configuration
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./ridenow.db")

# Use SQLite for development, PostgreSQL for production
if DATABASE_URL.startswith("sqlite"):
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
else:
    engine = create_engine(DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# User model (base class for passengers and drivers)
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    phone = Column(String, unique=True, index=True, nullable=False)
    password = Column(String, nullable=False)
    full_name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True)
    user_type = Column(String, nullable=False)  # 'passenger' or 'driver'
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Passenger model
class Passenger(Base):
    __tablename__ = "passengers"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    phone = Column(String, unique=True, index=True, nullable=False)
    full_name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationship with rides
    rides = relationship("Ride", back_populates="passenger")

# Driver model
class Driver(Base):
    __tablename__ = "drivers"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    phone = Column(String, unique=True, index=True, nullable=False)
    full_name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True)
    license_number = Column(String, unique=True)
    vehicle_number = Column(String)
    vehicle_type = Column(String)  # car, bike, auto
    is_online = Column(Boolean, default=False)
    is_verified = Column(Boolean, default=False)
    current_lat = Column(Float)
    current_lng = Column(Float)
    last_location_update = Column(DateTime)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationship with rides
    rides = relationship("Ride", back_populates="driver")

# Ride model
class Ride(Base):
    __tablename__ = "rides"
    
    id = Column(Integer, primary_key=True, index=True)
    passenger_id = Column(Integer, ForeignKey("passengers.id"), nullable=False)
    driver_id = Column(Integer, ForeignKey("drivers.id"), nullable=True)
    
    # Pickup location
    pickup_lat = Column(Float, nullable=False)
    pickup_lng = Column(Float, nullable=False)
    pickup_address = Column(String, nullable=False)
    
    # Drop location
    drop_lat = Column(Float, nullable=False)
    drop_lng = Column(Float, nullable=False)
    drop_address = Column(String, nullable=False)
    
    # Ride details
    city = Column(String, nullable=False)
    status = Column(String, default="requested")  # requested, accepted, arrived, started, completed, cancelled
    fare = Column(Float)
    distance_km = Column(Float)
    duration_minutes = Column(Float)
    
    # Timestamps
    requested_at = Column(DateTime, default=datetime.utcnow)
    accepted_at = Column(DateTime)
    arrived_at = Column(DateTime)
    started_at = Column(DateTime)
    completed_at = Column(DateTime)
    cancelled_at = Column(DateTime)
    
    # Additional info
    notes = Column(Text)
    payment_status = Column(String, default="pending")
    
    # Relationships
    passenger = relationship("Passenger", back_populates="rides")
    driver = relationship("Driver", back_populates="rides")

# Create all tables
def create_tables():
    Base.metadata.create_all(bind=engine)
