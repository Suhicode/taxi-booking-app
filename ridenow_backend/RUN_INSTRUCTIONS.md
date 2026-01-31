# RideNow Backend - Quick Start Guide

## 🚀 Setup & Run Instructions

### Prerequisites
- Python 3.8+
- pip or pipenv

### 1. Install Dependencies
```bash
cd ridenow_backend
pip install -r requirements.txt
```

### 2. Setup Environment
```bash
# Copy environment template
cp .env.example .env

# The .env file is already configured for development
# DATABASE_URL=sqlite:///./ridenow.db
# SECRET_KEY=ridenow-super-secret-key-change-in-production-2024
```

### 3. Run the Backend Server
```bash
# Method 1: Direct Python
python main.py

# Method 2: Using uvicorn
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### 4. Verify Server is Running
Open your browser and visit:
- Health Check: http://localhost:8000
- API Docs: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

### 5. Test the APIs

#### Test Passenger Registration
```bash
curl -X POST "http://localhost:8000/api/auth/passenger/register" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+1234567890",
    "password": "password123",
    "full_name": "John Doe",
    "email": "john@example.com"
  }'
```

#### Test Driver Registration
```bash
curl -X POST "http://localhost:8000/api/auth/driver/register" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+0987654321",
    "password": "password123",
    "full_name": "Jane Smith",
    "email": "jane@example.com",
    "license_number": "DL123456",
    "vehicle_number": "ABC-1234",
    "vehicle_type": "car"
  }'
```

## 📱 Flutter App Integration

### Update Flutter API Configuration

#### Customer App (customer_app/lib/services/api_service.dart)
```dart
class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    } else {
      return 'http://10.0.2.2:8000/api';  // Android emulator
    }
  }
  
  static String get wsUrl {
    if (kIsWeb) {
      return 'ws://localhost:8000/ws';
    } else {
      return 'ws://10.0.2.2:8000/ws';  // Android emulator
    }
  }
}
```

#### Driver App (driver_app/lib/services/api_service.dart)
```dart
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8000/api';  // Android emulator
  static const String wsUrl = 'ws://10.0.2.2:8000/ws';
}
```

### Run Flutter Apps

#### Customer App
```bash
cd customer_app
flutter run
```

#### Driver App
```bash
cd driver_app
flutter run
```

## 🧪 Complete Test Flow

### 1. Register & Login as Passenger
```bash
# Register passenger
curl -X POST "http://localhost:8000/api/auth/passenger/register" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+1111111111",
    "password": "pass123",
    "full_name": "Test Passenger",
    "email": "passenger@test.com"
  }'

# Save the access_token from response
```

### 2. Register & Login as Driver
```bash
# Register driver
curl -X POST "http://localhost:8000/api/auth/driver/register" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+2222222222",
    "password": "pass123",
    "full_name": "Test Driver",
    "email": "driver@test.com",
    "license_number": "DL999999",
    "vehicle_number": "XYZ-9999",
    "vehicle_type": "car"
  }'

# Save the access_token from response
```

### 3. Go Online as Driver
```bash
# Use driver token
curl -X PUT "http://localhost:8000/api/drivers/status" \
  -H "Authorization: Bearer DRIVER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"is_online": true}'
```

### 4. Update Driver Location
```bash
curl -X PUT "http://localhost:8000/api/drivers/location" \
  -H "Authorization: Bearer DRIVER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "lat": 40.7128,
    "lng": -74.0060
  }'
```

### 5. Request Ride as Passenger
```bash
# Use passenger token
curl -X POST "http://localhost:8000/api/rides/request" \
  -H "Authorization: Bearer PASSENGER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "pickup_lat": 40.7128,
    "pickup_lng": -74.0060,
    "pickup_address": "Times Square, NYC",
    "drop_lat": 40.7589,
    "drop_lng": -73.9851,
    "drop_address": "Central Park, NYC",
    "city": "New York"
  }'
```

### 6. Accept Ride as Driver
```bash
# Use ride ID from step 5
curl -X POST "http://localhost:8000/api/rides/1/accept" \
  -H "Authorization: Bearer DRIVER_ACCESS_TOKEN"
```

### 7. Complete Ride
```bash
curl -X POST "http://localhost:8000/api/rides/1/complete" \
  -H "Authorization: Bearer DRIVER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "final_fare": 150.50,
    "duration_minutes": 25
  }'
```

## 🔧 Common Issues & Solutions

### Issue: "Connection refused" on Flutter apps
**Solution**: Make sure backend is running on `http://10.0.2.2:8000` for Android emulator

### Issue: CORS errors
**Solution**: CORS is already configured. If using different ports, update `main.py`

### Issue: "Invalid authentication credentials"
**Solution**: Check that you're using the correct token for the right user type

### Issue: Database errors
**Solution**: Delete `ridenow.db` file and restart the server to recreate database

## 📊 Monitoring

### Check Server Logs
The server logs will show:
- Database table creation
- API requests
- WebSocket connections
- Error messages

### Database File
For SQLite development, the database file is created as `ridenow.db` in the project root.

## 🚀 Production Deployment

### Environment Variables
```bash
export DATABASE_URL="postgresql://user:pass@localhost/ridenow"
export SECRET_KEY="your-production-secret-key"
export HOST="0.0.0.0"
export PORT="8000"
```

### Using Docker
```bash
docker build -t ridenow-backend .
docker run -p 8000:8000 ridenow-backend
```

## ✅ Success Checklist

- [ ] Backend server running on port 8000
- [ ] Database tables created successfully
- [ ] Passenger registration/login working
- [ ] Driver registration/login working
- [ ] Driver can go online/offline
- [ ] Location updates working
- [ ] Ride requests created successfully
- [ ] Ride acceptance working
- [ ] Ride completion working
- [ ] Flutter apps can connect to backend
- [ ] WebSocket connections established

## 🆘 Troubleshooting

If you encounter any issues:

1. **Check server logs** for error messages
2. **Verify database file** exists and is writable
3. **Test with curl commands** first
4. **Check network connectivity** between Flutter and backend
5. **Review token usage** - ensure correct tokens for correct endpoints

For detailed API documentation, visit: http://localhost:8000/docs
