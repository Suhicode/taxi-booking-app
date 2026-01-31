# RideNow Backend

A FastAPI-based ride-hailing backend service similar to Uber/Ola.

## Features

- **Authentication**: JWT-based auth for passengers and drivers
- **Ride Management**: Complete ride lifecycle from request to completion
- **Real-time Communication**: WebSocket support for live updates
- **Location Services**: Driver location tracking and nearby driver search
- **Database**: SQLAlchemy ORM with SQLite (dev) / PostgreSQL (prod)
- **CORS Support**: Configured for frontend integration

## Quick Start

### 1. Install Dependencies
```bash
cd ridenow_backend
pip install -r requirements.txt
```

### 2. Environment Setup
```bash
cp .env.example .env
# Edit .env with your configuration
```

### 3. Run the Server
```bash
python main.py
```

The server will start at `http://localhost:8000`

### 4. Access API Documentation
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Project Structure

```
ridenow_backend/
├── main.py                 # FastAPI app entry point
├── requirements.txt        # Python dependencies
├── .env                   # Environment variables
├── .env.example           # Environment template
├── models/
│   ├── database.py        # SQLAlchemy models
│   └── schemas.py         # Pydantic schemas
├── routers/
│   ├── auth.py           # Authentication endpoints
│   ├── passengers.py     # Passenger endpoints
│   ├── drivers.py        # Driver endpoints
│   └── rides.py          # Ride endpoints & WebSocket
├── utils/
│   └── auth.py           # JWT utilities
├── API_EXAMPLES.md       # API usage examples
└── README.md             # This file
```

## API Endpoints

### Authentication
- `POST /api/auth/passenger/register` - Register passenger
- `POST /api/auth/passenger/login` - Passenger login
- `POST /api/auth/driver/register` - Register driver
- `POST /api/auth/driver/login` - Driver login

### Passengers
- `GET /api/passengers/profile` - Get passenger profile
- `GET /api/passengers/active-rides` - Get active rides
- `GET /api/passengers/rides/history` - Get ride history

### Drivers
- `GET /api/drivers/profile` - Get driver profile
- `PUT /api/drivers/location` - Update driver location
- `PUT /api/drivers/status` - Update online/offline status
- `GET /api/drivers/rides` - Get driver rides
- `GET /api/drivers/earnings` - Get earnings summary

### Rides
- `POST /api/rides/request` - Request a ride
- `POST /api/rides/{id}/accept` - Accept a ride
- `POST /api/rides/{id}/complete` - Complete a ride
- `GET /api/rides/{id}` - Get ride details

### WebSockets
- `ws://localhost:8000/api/rides/ws/driver/{driver_id}` - Driver connection
- `ws://localhost:8000/api/rides/ws/passenger/{passenger_id}` - Passenger connection

## WebSocket Message Types

### Driver Messages
- `ride_request` - New ride request
- `ride_taken` - Ride taken by another driver

### Passenger Messages
- `driver_assigned` - Driver assigned to ride
- `driver_location_update` - Driver location updates
- `ride_completed` - Ride completed
- `ride_cancelled` - Ride cancelled

## Database Schema

### Users
- `id`, `phone`, `password`, `full_name`, `email`, `user_type`

### Passengers
- `id`, `user_id`, `phone`, `full_name`, `email`

### Drivers
- `id`, `user_id`, `phone`, `full_name`, `email`, `license_number`, `vehicle_number`, `vehicle_type`, `is_online`, `current_lat`, `current_lng`

### Rides
- `id`, `passenger_id`, `driver_id`, `pickup_lat`, `pickup_lng`, `pickup_address`, `drop_lat`, `drop_lng`, `drop_address`, `city`, `status`, `fare`, `distance_km`, `duration_minutes`

## Ride Status Flow
1. `requested` - Ride requested by passenger
2. `accepted` - Ride accepted by driver
3. `arrived` - Driver arrived at pickup location
4. `started` - Ride started
5. `completed` - Ride completed
6. `cancelled` - Ride cancelled

## Frontend Integration

### Flutter Apps Integration

The backend is designed to work seamlessly with the existing Flutter apps:

#### Customer App
- Base URL: `http://10.0.2.2:8000/api` (Android emulator)
- WebSocket URL: `ws://10.0.2.2:8000/ws`
- Uses JWT tokens stored in FlutterSecureStorage
- Handles real-time ride updates via WebSocket

#### Driver App
- Base URL: `http://10.0.2.2:8000/api` (Android emulator)
- WebSocket URL: `ws://10.0.2.2:8000/ws`
- Periodic location updates every 10 seconds when online
- Receives ride requests via WebSocket

### Common Integration Issues & Solutions

#### CORS Issues
```python
# Already configured in main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

#### Authentication Headers
```dart
// Flutter HTTP request with auth
final response = await http.get(
  Uri.parse('${ApiConfig.baseUrl}/passengers/profile'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
);
```

#### WebSocket Connection
```dart
// Flutter WebSocket connection
final channel = WebSocketChannel.connect(
  Uri.parse('${ApiConfig.wsUrl}/driver/$driverId'),
);
```

## Development

### Running Tests
```bash
# Add tests directory and run
pytest tests/
```

### Database Migrations
```bash
# For production with PostgreSQL
alembic init alembic
alembic revision --autogenerate -m "Initial migration"
alembic upgrade head
```

### Environment Variables
- `DATABASE_URL` - Database connection string
- `SECRET_KEY` - JWT secret key
- `HOST` - Server host (default: 0.0.0.0)
- `PORT` - Server port (default: 8000)

## Production Deployment

### Using Docker
```dockerfile
FROM python:3.11

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Using PostgreSQL
```bash
# Install psycopg2-binary
pip install psycopg2-binary

# Update .env
DATABASE_URL=postgresql://username:password@localhost/ridenow
```

## Security Notes

- Change `SECRET_KEY` in production
- Use HTTPS in production
- Implement rate limiting
- Validate input data
- Use environment variables for sensitive data

## API Examples

See `API_EXAMPLES.md` for detailed API usage examples and curl commands.

## Support

For issues and questions:
1. Check the API documentation at `/docs`
2. Review the API examples
3. Check the Flutter app integration notes
