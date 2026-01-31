# Zone-based Fare Estimation Backend

A comprehensive backend system for zone-based fare estimation with real-time driver tracking, built with Node.js, Express, Postgres + PostGIS, Redis, and Socket.IO.

## Features

- **Zone-based Pricing**: Dynamic fare calculation based on geographic zones
- **Real-time Driver Tracking**: Redis geospatial queries for nearby drivers
- **Socket.IO Integration**: Real-time location updates and trip tracking
- **Admin Zone Management**: API endpoints for creating and managing zones
- **Vehicle Type Support**: Different pricing for bike, scooty, standard, comfort, premium, XL
- **Surge Pricing**: Configurable surge multipliers per zone

## Setup Instructions

### Prerequisites

- Node.js 16+
- PostgreSQL 12+ with PostGIS extension
- Redis 6+
- npm or yarn

### Database Setup

1. **Create Database**
```sql
CREATE DATABASE taxi_fare_db;
CREATE EXTENSION IF NOT EXISTS postgis;
```

2. **Run Schema**
```bash
psql -d taxi_fare_db -f schema.sql
```

### Environment Setup

1. **Copy Environment Variables**
```bash
cp .env.example .env
```

2. **Update .env file**
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=taxi_fare_db
DB_USER=postgres
DB_PASSWORD=your_password
REDIS_HOST=localhost
REDIS_PORT=6379
PORT=3000
```

### Install Dependencies

```bash
npm install
```

### Start Server

```bash
# Development
npm run dev

# Production
npm start
```

## API Endpoints

### Zone Detection
```
POST /api/v1/zone-for-point
{
  "lat": 19.0760,
  "lon": 72.8777
}
```

### Fare Estimation
```
POST /api/v1/estimate-fare
{
  "pickup": { "lat": 19.0760, "lon": 72.8777 },
  "drop": { "lat": 19.1198, "lon": 72.9059 },
  "usePickupZoneRates": true,
  "vehicleType": "standard"
}
```

### Driver Location Updates
```
POST /api/v1/driver-location
{
  "driverId": "driver123",
  "lat": 19.0760,
  "lon": 72.8777
}
```

### Nearby Drivers
```
GET /api/v1/nearby-drivers?lat=19.0760&lon=72.8777&radius=5
```

### Zone Management
```
POST /api/v1/zones
{
  "name": "South Mumbai",
  "slug": "south-mumbai",
  "geom": {"type":"Polygon","coordinates":[...]},
  "base_fare": 40.00,
  "per_km": 18.00,
  "per_min": 2.50,
  "minimum_fare": 60.00,
  "surge_enabled": true
}
```

## Socket.IO Events

### Driver Location Updates
```javascript
socket.emit('driver-location-update', {
  driverId: 'driver123',
  lat: 19.0760,
  lon: 72.8777
});
```

### Trip Tracking
```javascript
// Rider subscribes
socket.emit('subscribe-trip', 'trip123');

// Driver sends updates
socket.emit('trip-location-update', {
  tripId: 'trip123',
  lat: 19.0760,
  lon: 72.8777
});

// Rider receives updates
socket.on('trip-location', (data) => {
  console.log('Driver location:', data);
});
```

## Sample Data

The schema includes sample zones for Mumbai:
- South Mumbai (Premium zone)
- Bandra West (Mid-range zone)
- Andheri East (Standard zone)

## Testing

```bash
# Test zone detection
curl -X POST http://localhost:3000/api/v1/zone-for-point \
  -H "Content-Type: application/json" \
  -d '{"lat": 19.0760, "lon": 72.8777}'

# Test fare estimation
curl -X POST http://localhost:3000/api/v1/estimate-fare \
  -H "Content-Type: application/json" \
  -d '{
    "pickup": {"lat": 19.0760, "lon": 72.8777},
    "drop": {"lat": 19.1198, "lon": 72.9059},
    "vehicleType": "standard"
  }'
```

## Architecture Notes

### Fare Calculation Logic
1. Detect pickup and drop zones using PostGIS ST_Contains
2. Get distance/duration from Directions API (currently mocked)
3. Check for zone-specific rate overrides
4. Apply vehicle type multipliers
5. Apply surge pricing
6. Ensure minimum fare
7. Round to nearest rupee

### Redis Geospatial Usage
- **GEOADD**: Store driver locations
- **GEORADIUS**: Find nearby drivers
- **GEOPOS**: Get driver coordinates
- **GEODIST**: Calculate distances

### Surge Pricing Implementation
The `getSurgeMultiplier()` function is stubbed and can be enhanced to:
- Analyze recent ride requests per zone
- Consider available drivers
- Factor in time of day, weather, events
- Cap multiplier at reasonable limits (e.g., 3.0x)

## Integration with Flutter App

To integrate this backend with your Flutter taxi app:

1. Update Flutter HTTP calls to use these endpoints
2. Replace mock fare calculation with API calls
3. Implement Socket.IO client in Flutter for real-time updates
4. Use zone-based pricing instead of simple distance calculation

## Future Enhancements

- Real Google Maps/Mapbox Directions API integration
- Advanced surge pricing algorithm
- Driver earnings calculation
- Trip history and analytics
- Payment gateway integration
- Push notifications for ride requests
