# RideNow Driver App

A dedicated Flutter application for taxi drivers to manage ride requests, track earnings, and manage their profile.

## Features

- **Driver Authentication**: Secure login and signup for drivers
- **Dashboard**: Overview of driver statistics and quick actions
- **Ride Requests**: View and accept/reject ride requests from customers
- **Profile Management**: Manage driver profile, vehicle information, and documents
- **Earnings Tracking**: Monitor daily, weekly, and monthly earnings
- **Real-time Updates**: Live notifications for new ride requests

## Getting Started

### Prerequisites

- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.10.3)
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd taxi/driver_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── driver_profile_model.dart
│   ├── ride_request_model.dart
│   └── ride_state.dart
├── screens/                  # UI screens
│   ├── driver_login_screen.dart
│   ├── driver_signup_screen.dart
│   └── driver_dashboard_screen.dart
├── services/                 # Business logic and API calls
│   ├── driver_auth_service.dart
│   ├── driver_service/
│   ├── driver_service_mock.dart
│   └── ride_booking_service.dart
├── widgets/                  # Reusable UI components
│   └── image_upload_widget.dart
└── utils/                    # Utility functions
```

## Demo Credentials

For testing purposes, use these demo credentials:

- **Email**: john@driver.com
- **Phone**: 9876543210

## Key Dependencies

- `flutter_map`: Free OpenStreetMap solution
- `provider`: State management
- `geolocator`: Location services
- `image_picker`: Image upload functionality
- `firebase_core` & `cloud_firestore`: Backend services (optional)

## Architecture

The app follows a clean architecture pattern with:

- **Presentation Layer**: Screens and widgets
- **Business Logic Layer**: Services and providers
- **Data Layer**: Models and repositories

## Future Enhancements

- [ ] GPS tracking and route optimization
- [ ] In-app navigation
- [ ] Payment integration
- [ ] Advanced analytics dashboard
- [ ] Multi-language support

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License.
