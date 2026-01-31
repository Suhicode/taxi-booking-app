# Customer WebSocket Events - Backend Implementation

## WebSocket Endpoints:
- `/ws/passenger/{passenger_id}` - Passenger connection

## Event Payloads:

### 1. driver_assigned
```json
{
  "type": "driver_assigned",
  "ride_id": 123,
  "driver": {
    "id": 456,
    "name": "John Driver",
    "phone": "9876543210",
    "vehicle_type": "Sedan",
    "vehicle_number": "TN-01-AB-1234",
    "current_lat": 13.0827,
    "current_lng": 80.2707,
    "rating": 4.8
  }
}
```

### 2. driver_location_update
```json
{
  "type": "driver_location_update",
  "ride_id": 123,
  "driver": {
    "current_lat": 13.0828,
    "current_lng": 80.2708
  }
}
```

### 3. ride_completed
```json
{
  "type": "ride_completed",
  "ride_id": 123,
  "final_fare": 150.50,
  "duration_minutes": 25
}
```

### 4. ride_cancelled
```json
{
  "type": "ride_cancelled",
  "ride_id": 123,
  "reason": "driver_unavailable"
}
```

## Map Marker Update Logic:

1. **Driver Assignment**: 
   - Show driver marker on map
   - Update ride status to 'accepted'
   - Show "Driver assigned! On the way..." notification

2. **Location Updates**:
   - Update driver marker position every 10 seconds
   - Smooth animation between positions
   - Maintain driver info in provider state

3. **Ride Completion**:
   - Remove driver marker
   - Update ride status to 'completed'
   - Show completion notification with fare

4. **Ride Cancellation**:
   - Remove driver marker
   - Update ride status to 'cancelled'
   - Show cancellation notification

## Implementation Notes:
- Use `notifyListeners()` to trigger UI updates
- Store driver position in provider state
- Handle connection loss with auto-reconnect
- Send heartbeat every 30 seconds to keep connection alive
