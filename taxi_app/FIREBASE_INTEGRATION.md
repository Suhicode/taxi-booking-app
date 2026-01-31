# Firebase Integration Guide

## Project Created ✅

You've successfully created a Firebase project called **"taxi"**. Now follow these steps to complete the integration.

## Step 1: Create Firestore Database

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your **"taxi"** project
3. Click **Build** → **Firestore Database**
4. Click **Create Database**
5. Choose settings:
   - **Location**: `asia-south1` (or nearest to you)
   - **Security Rules**: Select **"Start in test mode"** (for development)
6. Click **Create**

## Step 2: Create Drivers Collection

Once Firestore is created:

1. Click **Start Collection**
2. Collection ID: `drivers`
3. Click **Next**
4. Add first document:
   - Document ID: `driver_001`
   - Click **Add field** and enter:

```
Field Name: name
Type: String
Value: John Doe

Field Name: vehicle_type
Type: String
Value: Standard

Field Name: status
Type: String
Value: available

Field Name: location
Type: Geo point
Value: latitude 13.0827, longitude 80.2707

Field Name: lastSeen
Type: Timestamp
Value: (current timestamp)
```

5. Click **Save**

## Step 3: Add More Sample Drivers

Click **Add document** and create these:

### Driver 2
```
Document ID: driver_002
name: Jane Smith
vehicle_type: Premium
status: available
location: GeoPoint(13.0850, 80.2730)
lastSeen: Timestamp.now()
```

### Driver 3
```
Document ID: driver_003
name: Mike Johnson
vehicle_type: Comfort
status: available
location: GeoPoint(13.0800, 80.2680)
lastSeen: Timestamp.now()
```

## Step 4: Download Configuration Files

### For Android:

1. Go to **Project Settings** (⚙️ icon)
2. Under **Your apps**, click your Android app
3. Click **google-services.json** download button
4. Save to: `android/app/google-services.json`

### For iOS:

1. Go to **Project Settings**
2. Under **Your apps**, click your iOS app
3. Click **GoogleService-Info.plist** download button
4. Add to Xcode project (File → Add Files)

## Step 5: Configure Google Maps API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Go to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **API Key**
5. Copy the API key

### Add to Android:

Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<application>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_API_KEY_HERE"/>
</application>
```

### Add to iOS:

Edit `ios/Runner/Info.plist`:
```xml
<key>com.google.ios.maps.API_KEY</key>
<string>YOUR_API_KEY_HERE</string>
```

## Step 6: Enable Required APIs

In Google Cloud Console, enable:
- ✅ Google Maps Platform
- ✅ Places API
- ✅ Cloud Firestore API

## Step 7: Update Firestore Security Rules

Go to **Firestore Database** → **Rules** tab and replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write for development
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

⚠️ **Note**: This is for development only. For production, implement proper authentication.

## Step 8: Run the Flutter App

```bash
cd taxi_app
flutter pub get
flutter run
```

## Verification Checklist

- [ ] Firebase project "taxi" created
- [ ] Firestore database created in `asia-south1`
- [ ] `drivers` collection created with 3 sample documents
- [ ] `google-services.json` downloaded and placed in `android/app/`
- [ ] `GoogleService-Info.plist` added to Xcode (iOS)
- [ ] Google Maps API key created
- [ ] API key added to AndroidManifest.xml
- [ ] API key added to Info.plist
- [ ] Google Maps API enabled in Cloud Console
- [ ] Places API enabled in Cloud Console
- [ ] Firestore security rules updated
- [ ] `flutter pub get` completed
- [ ] App runs without errors

## Testing Real-Time Drivers

Once the app is running:

1. Open the app on your device/emulator
2. Grant location permission
3. You should see the map with your current location
4. Driver markers should appear on the map (from Firestore)
5. Tap on the map to set a destination
6. Select a vehicle type to see estimated price
7. Click "Request Ride" to book

## Troubleshooting

### "Google Maps API key not found"
- Verify API key is in AndroidManifest.xml and Info.plist
- Ensure Maps SDK is enabled in Google Cloud Console

### "Firestore connection failed"
- Check `google-services.json` is in `android/app/`
- Verify Firestore security rules allow read/write
- Check internet connection

### "No drivers showing"
- Verify `drivers` collection exists in Firestore
- Check driver documents have correct structure
- Ensure `status` field is set to "available"
- Verify `location` field is a GeoPoint

### "Location permission denied"
- Grant permission in app settings
- For Android, check AndroidManifest.xml has location permissions
- For iOS, check Info.plist has location descriptions

## Next Steps

1. ✅ Complete Firebase setup (this guide)
2. ✅ Run tests: `flutter test`
3. ✅ Run app: `flutter run`
4. 📝 Implement authentication (Firebase Auth)
5. 📝 Add payment integration (Stripe/Razorpay)
6. 📝 Deploy to production

## Support

- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Firebase Plugin](https://firebase.flutter.dev/)
- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
