# 🚀 Quick Integration Guide

## Step-by-Step Setup

### 1. Backend Setup (5 minutes)

```bash
# Navigate to backend
cd backend

# Install dependencies
npm install

# Copy environment file
cp env.example .env

# Edit .env with your database credentials
# DB_HOST=localhost
# DB_PORT=5432
# DB_NAME=taxi_fare_db
# DB_USER=postgres
# DB_PASSWORD=your_password

# Create database (in PostgreSQL)
createdb taxi_fare_db
psql -d taxi_fare_db -c "CREATE EXTENSION IF NOT EXISTS postgis;"

# Run schema
psql -d taxi_fare_db -f schema.sql

# Start server
npm run dev
```

### 2. Flutter App Setup (2 minutes)

```bash
# Install dependencies
flutter pub get

# Update API base URL
# Edit: lib/services/api_client.dart
# Change: static const String baseUrl = 'http://YOUR_IP:3000/api/v1';
# 
# For Android Emulator: http://10.0.2.2:3000/api/v1
# For Physical Device: http://192.168.x.x:3000/api/v1 (your computer's IP)
```

### 3. Add Routes (2 minutes)

Update `lib/main.dart` or your route configuration:

```dart
import 'screens/auth/forgot_password_screen.dart';
import 'screens/ride/ride_tracking_screen.dart';
import 'screens/ride/ride_completion_screen.dart';
import 'screens/customer/ride_history_screen.dart';

// In MaterialApp:
routes: {
  '/forgot-password': (context) => const ForgotPasswordScreen(),
  // Add other routes as needed
},
```

### 4. Update Booking Screen (5 minutes)

In `lib/pages/customer_book_ride.dart`:

**Replace:**
```dart
import '../services/ride_booking_service.dart';
```

**With:**
```dart
import '../services/backend_ride_service.dart';
```

**Update ride creation:**
```dart
// Old:
final rideId = await RideBookingService.createRideRequest(...);

// New:
final backendService = BackendRideService();
final response = await backendService.createRideRequest(
  customerId: 'customer_123',
  customerName: 'John Doe',
  customerPhone: '+1234567890',
  pickupLocation: _pickupLocation!,
  pickupAddress: _pickupText,
  destinationLocation: _destination!,
  destinationAddress: _destinationText,
  vehicleType: _selectedVehicle,
  estimatedFare: _estimatedPrice.toDouble(),
  distance: distance,
);

if (response.success) {
  final rideId = response.data['rideId'].toString();
  // Navigate to tracking screen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => RideTrackingScreen(
        rideId: rideId,
        ride: rideRequest, // Create RideRequestModel from response
      ),
    ),
  );
}
```

### 5. Update Driver Dashboard (5 minutes)

In `lib/screens/driver/driver_dashboard_screen.dart`:

**Add imports:**
```dart
import '../../services/backend_ride_service.dart';
import '../../services/socket_service.dart';
```

**Update accept ride:**
```dart
// Old:
final success = await RideBookingService.acceptRide(...);

// New:
final backendService = BackendRideService();
final response = await backendService.acceptRide(
  ride.id,
  _currentDriver!.id,
  _currentDriver!.name,
);

if (response.success) {
  // Handle success
}
```

**Add Socket.IO listener for new ride requests:**
```dart
@override
void initState() {
  super.initState();
  _connectSocket();
  _loadPendingRides();
}

void _connectSocket() {
  final socketService = SocketService();
  socketService.connect();
  
  socketService.newRideRequestStream.listen((data) {
    // Show new ride request notification
    _loadPendingRides(); // Refresh list
  });
}
```

### 6. Test the Flow

1. **Start Backend:**
   ```bash
   cd backend
   npm run dev
   ```

2. **Run Flutter App:**
   ```bash
   flutter run
   ```

3. **Test Ride Booking:**
   - Open customer booking screen
   - Select pickup and destination
   - Choose vehicle type
   - Click "Request Ride"
   - Should navigate to tracking screen

4. **Test Driver Acceptance:**
   - Open driver dashboard
   - Should see new ride requests
   - Accept a ride
   - Customer should see status update

---

## 🔧 Configuration Checklist

- [ ] Backend server running on port 3000
- [ ] Database created and schema applied
- [ ] `.env` file configured
- [ ] API base URL updated in `api_client.dart`
- [ ] Socket.IO URL configured (if different)
- [ ] Routes added to main app
- [ ] Dependencies installed (`flutter pub get`)

---

## 🐛 Common Issues

### "Connection refused" error
- **Solution**: Check backend is running and IP address is correct
- For Android emulator, use `10.0.2.2` instead of `localhost`

### "Socket.IO connection failed"
- **Solution**: Ensure backend Socket.IO is running
- Check CORS settings in backend

### "Database connection error"
- **Solution**: Verify PostgreSQL is running
- Check credentials in `.env` file
- Ensure PostGIS extension is installed

---

## 📞 Need Help?

1. Check `backend/SETUP_GUIDE.md` for detailed setup
2. Check `IMPLEMENTATION_SUMMARY.md` for feature list
3. Review error messages in console
4. Verify all dependencies are installed

---

**You're all set! Start testing your integrated app! 🎉**
