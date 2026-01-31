# RideNow Backend API Examples

## Base URL
- Local Development: `http://localhost:8000/api`
- Android Emulator: `http://10.0.2.2:8000/api`

## Authentication Endpoints

### Passenger Registration
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

**Response:**
```json
{
  "success": true,
  "message": "Passenger registered successfully",
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "token_type": "bearer",
    "user_data": {
      "id": 1,
      "phone": "+1234567890",
      "full_name": "John Doe",
      "email": "john@example.com",
      "user_type": "passenger"
    }
  }
}
```

### Passenger Login
```bash
curl -X POST "http://localhost:8000/api/auth/passenger/login" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+1234567890",
    "password": "password123"
  }'
```

### Driver Registration
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

### Driver Login
```bash
curl -X POST "http://localhost:8000/api/auth/driver/login" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+0987654321",
    "password": "password123"
  }'
```

## Passenger Endpoints

### Get Profile
```bash
curl -X GET "http://localhost:8000/api/passengers/profile" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Request Ride
```bash
curl -X POST "http://localhost:8000/api/rides/request" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "pickup_lat": 40.7128,
    "pickup_lng": -74.0060,
    "pickup_address": "Times Square, New York",
    "drop_lat": 40.7589,
    "drop_lng": -73.9851,
    "drop_address": "Central Park, New York",
    "city": "New York",
    "notes": "Please hurry, I'm late!"
  }'
```

### Get Active Rides
```bash
curl -X GET "http://localhost:8000/api/passengers/active-rides" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Get Ride History
```bash
curl -X GET "http://localhost:8000/api/passengers/rides/history" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## Driver Endpoints

### Get Profile
```bash
curl -X GET "http://localhost:8000/api/drivers/profile" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Update Location
```bash
curl -X PUT "http://localhost:8000/api/drivers/location" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "lat": 40.7128,
    "lng": -74.0060
  }'
```

### Update Status (Go Online/Offline)
```bash
curl -X PUT "http://localhost:8000/api/drivers/status" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "is_online": true
  }'
```

### Accept Ride
```bash
curl -X POST "http://localhost:8000/api/rides/123/accept" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Complete Ride
```bash
curl -X POST "http://localhost:8000/api/rides/123/complete" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "final_fare": 150.50,
    "duration_minutes": 25
  }'
```

### Get Driver Rides
```bash
curl -X GET "http://localhost:8000/api/drivers/rides" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Get Driver Earnings
```bash
curl -X GET "http://localhost:8000/api/drivers/earnings" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## Ride Endpoints

### Get Ride Details
```bash
curl -X GET "http://localhost:8000/api/rides/123" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## WebSocket Connections

### Driver WebSocket
```javascript
// Connect to driver WebSocket
const ws = new WebSocket('ws://localhost:8000/api/rides/ws/driver/1');

// Listen for messages
ws.onmessage = function(event) {
    const message = JSON.parse(event.data);
    console.log('Received:', message);
    
    switch(message.type) {
        case 'ride_request':
            // Handle new ride request
            handleRideRequest(message);
            break;
        case 'ride_taken':
            // Handle ride taken by another driver
            console.log('Ride was taken by another driver');
            break;
    }
};

// Send location update
function sendLocationUpdate(lat, lng) {
    ws.send(JSON.stringify({
        type: 'location_update',
        lat: lat,
        lng: lng
    }));
}

// Accept ride
function acceptRide(rideId) {
    ws.send(JSON.stringify({
        type: 'accept_ride',
        ride_id: rideId
    }));
}

// Reject ride
function rejectRide(rideId) {
    ws.send(JSON.stringify({
        type: 'reject_ride',
        ride_id: rideId
    }));
}
```

### Passenger WebSocket
```javascript
// Connect to passenger WebSocket
const ws = new WebSocket('ws://localhost:8000/api/rides/ws/passenger/1');

// Listen for messages
ws.onmessage = function(event) {
    const message = JSON.parse(event.data);
    console.log('Received:', message);
    
    switch(message.type) {
        case 'driver_assigned':
            // Handle driver assignment
            handleDriverAssigned(message);
            break;
        case 'driver_location_update':
            // Handle driver location update
            updateDriverLocation(message);
            break;
        case 'ride_completed':
            // Handle ride completion
            handleRideCompleted(message);
            break;
    }
};
```

## Error Response Format
```json
{
  "detail": "Error message description"
}
```

## Common HTTP Status Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error
