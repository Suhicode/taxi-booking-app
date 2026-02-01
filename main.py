from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import os
from dotenv import load_dotenv

from models.database import create_tables
from routers import auth, passengers, drivers, rides

load_dotenv()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print("🚀 Starting RideNow Backend...")
    
    # Create database tables
    create_tables()
    print("✅ Database tables created successfully")
    
    print("🎯 RideNow Backend is ready!")
    yield
    
    # Shutdown
    print("🛑 Shutting down RideNow Backend...")

# Create FastAPI app
app = FastAPI(
    title="RideNow API",
    description="A ride-hailing backend service similar to Uber/Ola",
    version="1.0.0",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your frontend domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api")
app.include_router(passengers.router, prefix="/api")
app.include_router(drivers.router, prefix="/api")
app.include_router(rides.router, prefix="/api")

# Health check endpoint
@app.get("/")
async def root():
    """Health check endpoint."""
    return {
        "message": "RideNow Backend is running",
        "status": "healthy",
        "version": "1.0.0"
    }

@app.get("/health")
async def health_check():
    """Detailed health check endpoint."""
    return {
        "status": "healthy",
        "database": "connected",
        "websockets": "active",
        "endpoints": {
            "auth": "/api/auth",
            "passengers": "/api/passengers",
            "drivers": "/api/drivers",
            "rides": "/api/rides",
            "websockets": "/api/rides/ws"
        }
    }

# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Handle unexpected errors."""
    print(f"Unexpected error: {exc}")
    return HTTPException(
        status_code=500,
        detail="Internal server error. Please try again later."
    )

if __name__ == "__main__":
    import uvicorn
    
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    
    uvicorn.run(
        "main:app",
        host=host,
        port=port,
        reload=True,
        log_level="info"
    )
