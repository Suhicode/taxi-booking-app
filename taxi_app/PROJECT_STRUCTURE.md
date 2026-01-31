# Taxi App - Restructured Project Architecture

## 📁 New Folder Structure

```
lib/
├── main.dart
├── app.dart                    # App configuration and providers
├── theme.dart                   # App theme and styling
│
├── models/                     # Data models and entities
│   ├── user/
│   │   ├── user_model.dart
│   │   ├── driver_profile_model.dart
│   │   └── auth_models.dart
│   ├── ride/
│   │   ├── ride_model.dart
│   │   ├── ride_request_model.dart
│   │   ├── ride_state.dart
│   │   └── ride_booking_state.dart
│   ├── vehicle/
│   │   └── vehicle_model.dart
│   ├── location/
│   │   └── location_model.dart
│   └── fare/
│       └── fare_model.dart
│
├── services/                   # Business logic and API services
│   ├── auth/
│   │   ├── auth_service.dart
│   │   ├── enhanced_auth_service.dart
│   │   └── auth_repository.dart
│   ├── location/
│   │   ├── location_service.dart
│   │   └── geocoding_service.dart
│   ├── driver/
│   │   ├── driver_service.dart
│   │   ├── driver_search_service.dart
│   │   └── driver_location_service.dart
│   ├── ride/
│   │   ├── ride_booking_service.dart
│   │   ├── fare_calculator.dart
│   │   └── pricing_service.dart
│   ├── maps/
│   │   ├── map_service.dart
│   │   └── directions_service.dart
│   ├── notification/
│   │   └── notification_service.dart
│   └── storage/
│       ├── cache_service.dart
│       └── secure_storage_service.dart
│
├── providers/                   # State management (Riverpod/BLoC/Provider)
│   ├── auth/
│   │   ├── auth_provider.dart
│   │   └── auth_state.dart
│   ├── ride/
│   │   ├── ride_provider.dart
│   │   ├── ride_booking_provider.dart
│   │   └── ride_state_provider.dart
│   ├── driver/
│   │   ├── driver_provider.dart
│   │   └── driver_location_provider.dart
│   ├── location/
│   │   └── location_provider.dart
│   └── user/
│       └── user_profile_provider.dart
│
├── screens/                    # UI Screens (organized by feature)
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── forgot_password_screen.dart
│   │   └── role_selection_screen.dart
│   ├── customer/
│   │   ├── customer_home_screen.dart
│   │   ├── book_ride_screen.dart
│   │   ├── ride_history_screen.dart
│   │   ├── payment_screen.dart
│   │   └── profile_screen.dart
│   ├── driver/
│   │   ├── driver_home_screen.dart
│   │   ├── driver_earnings_screen.dart
│   │   ├── driver_profile_screen.dart
│   │   └── driver_settings_screen.dart
│   ├── ride/
│   │   ├── ride_tracking_screen.dart
│   │   ├── ride_completion_screen.dart
│   │   └── ride_rating_screen.dart
│   ├── common/
│   │   ├── splash_screen.dart
│   │   ├── onboarding_screen.dart
│   │   ├── settings_screen.dart
│   │   └── help_screen.dart
│   └── admin/
│       ├── admin_dashboard_screen.dart
│       ├── user_management_screen.dart
│       └── analytics_screen.dart
│
├── widgets/                    # Reusable UI components
│   ├── common/
│   │   ├── custom_button.dart
│   │   ├── custom_text_field.dart
│   │   ├── loading_widget.dart
│   │   ├── error_widget.dart
│   │   └── empty_state_widget.dart
│   ├── maps/
│   │   ├── map_widget.dart
│   │   ├── location_marker.dart
│   │   └── route_polyline.dart
│   ├── ride/
│   │   ├── ride_card.dart
│   │   ├── fare_display.dart
│   │   ├── vehicle_selector.dart
│   │   └── driver_info_card.dart
│   ├── auth/
│   │   ├── auth_form.dart
│   │   ├── social_login_button.dart
│   │   └── permission_dialog.dart
│   └── forms/
│       ├── address_form.dart
│       ├── payment_form.dart
│       └── profile_form.dart
│
└── utils/                       # Utility functions and helpers
    ├── constants/
    │   ├── app_constants.dart
    │   ├── api_constants.dart
    │   └── route_constants.dart
    ├── extensions/
    │   ├── string_extensions.dart
    │   ├── datetime_extensions.dart
    │   └── context_extensions.dart
    ├── validators/
    │   ├── form_validators.dart
    │   └── input_validators.dart
    ├── helpers/
    │   ├── date_helper.dart
    │   ├── currency_helper.dart
    │   └── format_helper.dart
    ├── formatters/
    │   ├── currency_formatter.dart
    │   └── date_formatter.dart
    └── error/
        ├── error_handler.dart
        └── error_logger.dart
```

## 🏗️ Architecture Principles

### 1. **Separation of Concerns**
- **Models**: Pure data classes with no business logic
- **Services**: Business logic, API calls, data manipulation
- **Providers**: State management and UI state
- **Screens**: UI components organized by feature
- **Widgets**: Reusable UI components
- **Utils**: Helper functions and utilities

### 2. **Feature-Based Organization**
- Each major feature (auth, ride, driver) has its own folder
- Related components are grouped together
- Easy to locate and maintain feature code
- Clear dependency flow between layers

### 3. **Dependency Flow**
```
Screens → Providers → Services → Models → Utils
   ↓         ↓         ↓        ↓
   UI     State    Logic   Data   Helpers
```

### 4. **Naming Conventions**
- **Files**: snake_case (e.g., `ride_booking_screen.dart`)
- **Classes**: PascalCase (e.g., `RideBookingScreen`)
- **Variables**: camelCase (e.g., `rideBookingState`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `API_BASE_URL`)

## 🚀 Migration Benefits

### Scalability
- **Easy Feature Addition**: New features get their own folder
- **Team Collaboration**: Clear ownership of different areas
- **Code Reusability**: Shared widgets and utilities
- **Testing**: Each layer can be tested independently

### Maintainability
- **Clear Structure**: Easy to navigate and understand
- **Reduced Coupling**: Dependencies flow one way
- **Modular Design**: Changes in one area don't affect others
- **Documentation**: Each folder has clear purpose

### Performance
- **Lazy Loading**: Load only what's needed
- **Caching**: Services handle data caching
- **Memory Management**: Clear disposal patterns
- **Build Optimization**: Organized imports reduce build times

## 📋 Implementation Steps

### Phase 1: Create Folder Structure
```bash
mkdir -p lib/models/{user,ride,vehicle,location,fare}
mkdir -p lib/services/{auth,location,driver,ride,maps,notification,storage}
mkdir -p lib/providers/{auth,ride,driver,location,user}
mkdir -p lib/screens/{auth,customer,driver,ride,common,admin}
mkdir -p lib/widgets/{common,maps,ride,auth,forms}
mkdir -p lib/utils/{constants,extensions,validators,helpers,formatters,error}
```

### Phase 2: Move Existing Files
```bash
# Move models
mv lib/models/user_model.dart lib/models/user/
mv lib/models/driver_profile_model.dart lib/models/user/
mv lib/models/ride_*.dart lib/models/ride/
mv lib/models/vehicle_*.dart lib/models/vehicle/

# Move services
mv lib/services/*_auth*.dart lib/services/auth/
mv lib/services/*_location*.dart lib/services/location/
mv lib/services/*_driver*.dart lib/services/driver/
mv lib/services/*_ride*.dart lib/services/ride/
mv lib/services/*_map*.dart lib/services/maps/
mv lib/services/error_handler.dart lib/utils/error/

# Move providers
mv lib/providers/*_auth*.dart lib/providers/auth/
mv lib/providers/*_ride*.dart lib/providers/ride/
mv lib/providers/*_driver*.dart lib/providers/driver/

# Move screens
mv lib/pages/customer_*.dart lib/screens/customer/
mv lib/pages/driver_*.dart lib/screens/driver/
mv lib/pages/*_auth*.dart lib/screens/auth/
mv lib/pages/*_ride*.dart lib/screens/ride/
```

### Phase 3: Update Imports
```dart
// Update all imports to reflect new structure
import '../models/user/user_model.dart';
import '../services/auth/auth_service.dart';
import '../providers/auth/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../widgets/auth/auth_form.dart';
import '../utils/error/error_handler.dart';
```

### Phase 4: Create App Configuration
```dart
// lib/app.dart
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RideProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        title: 'Taxi App',
        home: SplashScreen(),
        routes: AppRoutes.routes,
      ),
    );
  }
}
```

## 🔧 Sample Code Structure

### Model Example
```dart
// lib/models/ride/ride_model.dart
class RideModel {
  final String id;
  final String customerId;
  final String driverId;
  final LatLng pickupLocation;
  final LatLng destinationLocation;
  final double fare;
  final RideStatus status;
  final DateTime createdAt;

  const RideModel({
    required this.id,
    required this.customerId,
    required this.driverId,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.fare,
    required this.status,
    required this.createdAt,
  });

  factory RideModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideModel(
      id: doc.id,
      customerId: data['customerId'] as String,
      driverId: data['driverId'] as String,
      pickupLocation: LatLng(
        data['pickupLatitude'] as double,
        data['pickupLongitude'] as double,
      ),
      destinationLocation: LatLng(
        data['destinationLatitude'] as double,
        data['destinationLongitude'] as double,
      ),
      fare: (data['fare'] as num).toDouble(),
      status: RideStatus.values.firstWhere(
        (status) => status.name == data['status'],
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'driverId': driverId,
      'pickupLatitude': pickupLocation.latitude,
      'pickupLongitude': pickupLocation.longitude,
      'destinationLatitude': destinationLocation.latitude,
      'destinationLongitude': destinationLocation.longitude,
      'fare': fare,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
```

### Service Example
```dart
// lib/services/ride/ride_booking_service.dart
class RideBookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<String> createRide({
    required RideModel ride,
  }) async {
    try {
      final docRef = await _firestore.collection('rides').add(ride.toFirestore());
      return docRef.id;
    } catch (e) {
      throw ErrorHandler.handleRuntimeErrors(
        () => throw e,
        operationName: 'Create Ride',
      );
    }
  }
  
  Future<List<RideModel>> getCustomerRides(String customerId) async {
    try {
      final snapshot = await _firestore
          .collection('rides')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => RideModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ErrorHandler.handleApiErrors(
        () => throw e,
        apiEndpoint: 'Get Customer Rides',
      );
    }
  }
}
```

### Provider Example
```dart
// lib/providers/ride/ride_provider.dart
class RideProvider extends ChangeNotifier {
  final RideBookingService _rideService = RideBookingService();
  
  List<RideModel> _rides = [];
  bool _isLoading = false;
  String? _error;

  List<RideModel> get rides => _rides;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCustomerRides(String customerId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final rides = await _rideService.getCustomerRides(customerId);
      _rides = rides;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> bookRide(RideModel ride) async {
    _setLoading(true);
    _clearError();
    
    try {
      final rideId = await _rideService.createRide(ride: ride);
      _rides.insert(0, ride.copyWith(id: rideId));
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
```

### Screen Example
```dart
// lib/screens/customer/book_ride_screen.dart
class BookRideScreen extends ConsumerStatefulWidget<RideProvider> {
  @override
  Widget build(BuildContext context) {
    final rideProvider = context.watch<RideProvider>();
    
    return Scaffold(
      appBar: AppBar(title: Text('Book Ride')),
      body: rideProvider.isLoading
          ? LoadingWidget()
          : rideProvider.error != null
              ? ErrorWidget(message: rideProvider.error!)
              : RideBookingForm(
                  onSubmit: (rideData) {
                    rideProvider.bookRide(rideData);
                    Navigator.pushNamed(context, '/ride-tracking');
                  },
                ),
    );
  }
}
```

## 🎯 Next Steps

1. **Create Folder Structure**: Set up all directories
2. **Move Files**: Organize existing code into new structure
3. **Update Imports**: Fix all import statements
4. **Create App Config**: Set up providers and routing
5. **Test Thoroughly**: Ensure everything works after restructuring
6. **Update Documentation**: Keep README and docs updated

This restructured architecture provides a solid foundation for scaling your taxi app with proper separation of concerns, maintainable code, and clear organization patterns.
