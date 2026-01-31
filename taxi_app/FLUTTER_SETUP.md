# Flutter Taxi Booking App - Setup & Testing Guide

## Overview

This document provides setup instructions, testing procedures, and configuration details for the Flutter Taxi Booking Customer App.

## Project Structure

```
lib/
├── pages/
│   └── customer_book_ride.dart       # Main customer booking page
├── services/
│   ├── driver_service.dart           # Firestore driver management
│   ├── location_service.dart         # Geolocation & Places API
│   └── pricing_service.dart          # Fare calculation logic
├── widgets/
│   └── vehicle_tile.dart             # Vehicle selection component
└── main.dart                         # App entry point

test/
├── pricing_service_test.dart         # Pricing logic unit tests
└── vehicle_tile_test.dart            # Widget tests

assets/
└── images/                           # Image assets (see README.md)
```

## Prerequisites

- Flutter SDK 3.10.3 or higher
- Dart 3.10.3 or higher
- Android Studio / VS Code with Flutter extensions
- Google Cloud Project with:
  - Google Maps API enabled
  - Google Places API enabled
  - Firebase project configured
- Physical device or emulator for testing

## Setup Instructions

### 1. Install Dependencies

```bash
cd taxi_app
flutter pub get
```

### 2. Configure Firebase

#### Android Setup

1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/`
3. Update `android/build.gradle`:
   ```gradle
   classpath 'com.google.gms:google-services:4.3.15'
   ```
4. Update `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

#### iOS Setup

1. Download `GoogleService-Info.plist` from Firebase Console
2. Add to Xcode project (Xcode → File → Add Files)
3. Ensure it's added to all targets

### 3. Configure Google Maps API

#### Android

Update `android/app/src/main/AndroidManifest.xml`:
```xml
<application>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
</application>
```

#### iOS

Update `ios/Runner/Info.plist`:
```xml
<key>com.google.ios.maps.API_KEY</key>
<string>YOUR_GOOGLE_MAPS_API_KEY</string>
```

### 4. Location Permissions

#### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to your location to show nearby drivers and calculate fares.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs access to your location for navigation and real-time driver tracking.</string>
```

## Running the App

### Development Mode

```bash
# Run on connected device
flutter run

# Run on specific device
flutter run -d <device_id>

# Run with verbose logging
flutter run -v
```

### Release Mode

```bash
flutter run --release
```

### Web (for testing)

```bash
flutter run -d chrome
```

## Testing

### Run All Tests

```bash
flutter test
```

### Run Specific Test File

```bash
flutter test test/pricing_service_test.dart
flutter test test/vehicle_tile_test.dart
```

### Run Tests with Coverage

```bash
flutter test --coverage
```

### Test Coverage Report

```bash
# Generate coverage report (requires lcov)
lcov --list coverage/lcov.info
```

## Firestore Setup for Testing

### Create Test Data

1. Go to Firebase Console → Firestore Database
2. Create a new collection: `drivers`
3. Add sample driver documents:

```javascript
// Document ID: driver_001
{
  "name": "John Doe",
  "vehicle_type": "Standard",
  "status": "available",
  "location": GeoPoint(13.0827, 80.2707),
  "lastSeen": Timestamp.now()
}

// Document ID: driver_002
{
  "name": "Jane Smith",
  "vehicle_type": "Premium",
  "status": "available",
  "location": GeoPoint(13.0850, 80.2730),
  "lastSeen": Timestamp.now()
}

// Document ID: driver_003
{
  "name": "Mike Johnson",
  "vehicle_type": "Comfort",
  "status": "busy",
  "location": GeoPoint(13.0800, 80.2680),
  "lastSeen": Timestamp.now()
}
```

### Seed Drivers via Node.js Script

```javascript
// seed_drivers.js
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'your-project-id'
});

const db = admin.firestore();

const drivers = [
  {
    id: 'driver_001',
    name: 'John Doe',
    vehicle_type: 'Standard',
    status: 'available',
    location: new admin.firestore.GeoPoint(13.0827, 80.2707),
    lastSeen: admin.firestore.Timestamp.now()
  },
  {
    id: 'driver_002',
    name: 'Jane Smith',
    vehicle_type: 'Premium',
    status: 'available',
    location: new admin.firestore.GeoPoint(13.0850, 80.2730),
    lastSeen: admin.firestore.Timestamp.now()
  }
];

async function seedDrivers() {
  for (const driver of drivers) {
    await db.collection('drivers').doc(driver.id).set({
      name: driver.name,
      vehicle_type: driver.vehicle_type,
      status: driver.status,
      location: driver.location,
      lastSeen: driver.lastSeen
    });
    console.log(`Seeded driver: ${driver.id}`);
  }
  console.log('All drivers seeded successfully');
}

seedDrivers().catch(console.error);
```

Run with:
```bash
node seed_drivers.js
```

## Pricing Configuration

Default pricing rates are configured in `lib/services/pricing_service.dart`:

| Vehicle Type | Base Fare | Per KM | Per Min | Min Fare |
|--------------|-----------|--------|---------|----------|
| Bike         | ₹20       | ₹10    | ₹1     | ₹30      |
| Scooty       | ₹25       | ₹12    | ₹1.2   | ₹35      |
| Standard     | ₹30       | ₹15    | ₹2     | ₹50      |
| Comfort      | ₹40       | ₹18    | ₹2.5   | ₹60      |
| Premium      | ₹60       | ₹25    | ₹3     | ₹80      |
| XL           | ₹80       | ₹30    | ₹4     | ₹100     |

### Additional Charges

- **Platform Commission**: 15%
- **Tax Rate**: 5%
- **Night Surcharge**: 1.25x (22:00 - 06:00)
- **Waiting Charge**: ₹2/min (after 3 free minutes)
- **Max Surge Multiplier**: 3.0x

## Environment Variables

Create `.env` file in project root (optional):

```env
GOOGLE_MAPS_API_KEY=your_api_key_here
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_API_KEY=your_firebase_api_key
```

## Troubleshooting

### Common Issues

1. **"Google Maps API key not found"**
   - Ensure API key is correctly added to AndroidManifest.xml and Info.plist
   - Verify API key has Maps SDK enabled in Google Cloud Console

2. **"Location permission denied"**
   - Grant location permission in app settings
   - For Android 6+, ensure runtime permissions are granted
   - Check AndroidManifest.xml has location permissions

3. **"Firestore connection failed"**
   - Verify Firebase project is initialized
   - Check Firestore security rules allow read/write
   - Ensure google-services.json is in correct location

4. **"No drivers showing on map"**
   - Verify Firestore has driver documents with correct structure
   - Check driver status is "available"
   - Ensure location field is a GeoPoint

5. **"Tests failing"**
   - Run `flutter pub get` to ensure all dependencies are installed
   - Clear build cache: `flutter clean && flutter pub get`
   - Run tests with verbose output: `flutter test -v`

## Performance Optimization

### Tips

1. **Map Performance**
   - Limit driver markers to visible area
   - Use clustering for large numbers of drivers
   - Implement marker filtering by vehicle type

2. **Firestore Optimization**
   - Add indexes for frequently queried fields
   - Use pagination for large datasets
   - Implement caching with Provider/Riverpod

3. **Location Updates**
   - Adjust `distanceFilter` in LocationSettings
   - Implement debouncing for location updates
   - Cache location data locally

## Future Enhancements

- [ ] Implement real Google Places autocomplete
- [ ] Add payment gateway integration
- [ ] Implement trip history and analytics
- [ ] Add driver rating system
- [ ] Implement emergency SOS feature
- [ ] Add multiple language support
- [ ] Implement offline mode with local caching

## Support & Documentation

- **Flutter Docs**: https://flutter.dev/docs
- **Firebase Docs**: https://firebase.google.com/docs
- **Google Maps API**: https://developers.google.com/maps
- **Firestore**: https://firebase.google.com/docs/firestore

## License

This project is proprietary and confidential.
