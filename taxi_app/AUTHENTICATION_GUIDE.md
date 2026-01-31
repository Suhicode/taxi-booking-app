# Production-Ready Authentication System Guide

## Overview
The `EnhancedAuthService` provides comprehensive, secure authentication with role-based access control, persistent sessions, and proper error handling for your Flutter taxi application.

## Key Features

### 🔐 **Secure Authentication**
- **Multi-Provider Support**: Email/Password, Google, Facebook, Apple Sign-In
- **Role-Based Access**: Customer, Driver, and Admin roles with proper separation
- **Persistent Sessions**: Secure storage with "Remember Me" functionality
- **Password Security**: Strong password requirements and secure reset flows
- **Data Validation**: Comprehensive input validation and sanitization

### 👥 **User Management**
- **Profile Management**: Update display names, photos, and role-specific data
- **Account Deletion**: Secure account deletion with data cleanup
- **Password Changes**: Secure password updates with re-authentication
- **Session Tracking**: Last login timestamps and activity monitoring

### 🔒 **Security Features**
- **Secure Storage**: Flutter Secure Storage for sensitive data
- **Token Management**: Automatic token refresh and cleanup
- **Error Handling**: User-friendly error messages with proper logging
- **Session Cleanup**: Complete logout with cache clearing

### 📱 **UI Integration**
- **State Management**: AuthProvider for reactive UI updates
- **Loading States**: Proper loading indicators during auth operations
- **Error Display**: User-friendly error messages
- **Role-Based UI**: Different interfaces for customers vs drivers

## Quick Usage Examples

### Basic Email Authentication
```dart
import 'package:your_app/services/enhanced_auth_service.dart';

// Sign in
final authService = EnhancedAuthService();
final result = await authService.signInWithEmailAndPassword(
  email: 'user@example.com',
  password: 'password123',
  rememberMe: true,
);

if (result.isSuccess) {
  print('Welcome ${result.profile!.displayName}');
  print('Role: ${result.role}');
} else {
  print('Error: ${result.errorMessage}');
}
```

### Registration with Role Selection
```dart
// Register new customer
final result = await authService.registerWithEmailAndPassword(
  email: 'customer@example.com',
  password: 'securePassword123',
  confirmPassword: 'securePassword123',
  displayName: 'John Doe',
  role: UserRole.customer,
);

// Register new driver
final driverResult = await authService.registerWithEmailAndPassword(
  email: 'driver@example.com',
  password: 'driverPassword123',
  confirmPassword: 'driverPassword123',
  displayName: 'Jane Driver',
  role: UserRole.driver,
  roleData: {
    'licenseNumber': 'DL123456',
    'vehicleType': 'Standard',
    'experience': '5 years',
  },
);
```

### Social Sign-In
```dart
// Google Sign-In
final googleResult = await authService.signInWithGoogle(role: UserRole.customer);

// Facebook Sign-In
final facebookResult = await authService.signInWithFacebook(role: UserRole.driver);

// Apple Sign-In
final appleResult = await authService.signInWithApple(role: UserRole.customer);
```

### Role-Based Access Control
```dart
// Check user role
final authService = EnhancedAuthService();

if (await authService.isCustomer) {
  // Show customer interface
  Navigator.pushReplacementNamed(context, '/customer-home');
} else if (await authService.isDriver) {
  // Show driver interface
  Navigator.pushReplacementNamed(context, '/driver-home');
} else if (await authService.isAdmin) {
  // Show admin interface
  Navigator.pushReplacementNamed(context, '/admin-dashboard');
}
```

### UI Integration with AuthProvider
```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider()..initialize(),
      child: MaterialApp(
        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return LoadingScreen();
        }
        
        if (authProvider.userProfile == null) {
          return LoginScreen();
        }
        
        // Role-based routing
        switch (authProvider.userProfile!.role) {
          case UserRole.customer:
            return CustomerHomeScreen();
          case UserRole.driver:
            return DriverHomeScreen();
          case UserRole.admin:
            return AdminDashboard();
        }
      },
    );
  }
}
```

## Integration Steps

### 1. Update Dependencies
Add to `pubspec.yaml`:
```yaml
dependencies:
  firebase_auth: ^4.17.5
  cloud_firestore: ^4.17.5
  google_sign_in: ^6.1.6
  flutter_facebook_auth: ^5.0.11
  sign_in_with_apple: ^5.0.0
  flutter_secure_storage: ^8.0.0
  shared_preferences: ^2.2.2
  crypto: ^3.0.3
  provider: ^6.0.5
```

### 2. Firebase Configuration
1. Enable Authentication in Firebase Console
2. Configure sign-in providers (Email/Password, Google, Facebook, Apple)
3. Set up Firestore for user profiles
4. Configure security rules for role-based access

### 3. Replace Existing Auth Service
```dart
// Before
import '../services/auth_service.dart';
final authService = AuthService();

// After
import '../services/enhanced_auth_service.dart';
final authService = EnhancedAuthService();
```

### 4. Update Login Screens
```dart
class LoginScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          body: Column(
            children: [
              if (authProvider.errorMessage != null)
                ErrorBanner(message: authProvider.errorMessage!),
              
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                onChanged: (value) => _email = value,
              ),
              
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (value) => _password = value,
              ),
              
              CheckboxListTile(
                title: Text('Remember Me'),
                value: _rememberMe,
                onChanged: (value) => _rememberMe = value ?? false,
              ),
              
              if (authProvider.isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () async {
                    final success = await authProvider.signIn(
                      email: _email,
                      password: _password,
                      rememberMe: _rememberMe,
                    );
                    
                    if (success) {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  },
                  child: Text('Sign In'),
                ),
            ],
          ),
        );
      },
    );
  }
}
```

### 5. Add Role Selection
```dart
class RoleSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          body: Column(
            children: [
              Text('I am a:'),
              
              ElevatedButton.icon(
                icon: Icon(Icons.person),
                label: Text('Customer'),
                onPressed: () => _selectRole(UserRole.customer),
              ),
              
              ElevatedButton.icon(
                icon: Icon(Icons.drive_eta),
                label: Text('Driver'),
                onPressed: () => _selectRole(UserRole.driver),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _selectRole(UserRole role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationScreen(role: role),
      ),
    );
  }
}
```

## Advanced Features

### Custom Role Data
```dart
// Driver-specific data during registration
final driverData = {
  'licenseNumber': 'DL123456',
  'vehicleType': 'Standard',
  'vehicleNumber': 'MH12AB1234',
  'experience': '5 years',
  'languages': ['English', 'Hindi'],
  'services': ['Airport', 'Outstation'],
};

// Customer-specific data
final customerData = {
  'preferredPayment': 'Credit Card',
  'emergencyContact': '+91 9876543210',
  'preferences': {
    'music': false,
    'ac': true,
    'smoking': false,
  },
};
```

### Session Management
```dart
class SessionManager {
  static Future<void> extendSession() async {
    final authService = EnhancedAuthService();
    final profile = await authService.getCurrentUserProfile();
    
    if (profile != null) {
      // Update last activity
      await authService._updateLastLogin(profile.uid);
    }
  }
  
  static Future<bool> isSessionValid() async {
    final profile = await EnhancedAuthService().getCurrentUserProfile();
    if (profile == null) return false;
    
    // Check if session is less than 24 hours old
    final now = DateTime.now();
    final lastLogin = profile.lastLogin;
    return now.difference(lastLogin).inHours < 24;
  }
}
```

### Security Monitoring
```dart
class SecurityMonitor {
  static Future<void> logSecurityEvent({
    required String userId,
    required String event,
    String? details,
  }) async {
    await FirebaseFirestore.instance.collection('security_logs').add({
      'userId': userId,
      'event': event,
      'details': details,
      'timestamp': Timestamp.now(),
      'ipAddress': await _getIPAddress(),
      'userAgent': await _getUserAgent(),
    });
  }
  
  static Future<void> detectSuspiciousActivity(String userId) async {
    final logs = await FirebaseFirestore.instance
        .collection('security_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();
    
    // Analyze for suspicious patterns
    final recentAttempts = logs.docs.where((doc) {
      final timestamp = (doc.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
      final timeDiff = DateTime.now().difference(timestamp.toDate());
      return timeDiff.inMinutes < 5;
    });
    
    if (recentAttempts.length > 5) {
      // Lock account temporarily
      await _lockAccount(userId);
      await logSecurityEvent(
        userId: userId,
        event: 'ACCOUNT_LOCKED',
        details: 'Too many failed attempts',
      );
    }
  }
}
```

## Production Considerations

### Security Rules for Firestore
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Admins can read all user profiles
    match /users/{userId} {
      allow read: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Security logs (admin only)
    match /security_logs/{logId} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

### Performance Optimization
```dart
class AuthCache {
  static final Map<String, UserProfile> _profileCache = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  static Future<UserProfile?> getCachedProfile(String uid) async {
    if (_profileCache.containsKey(uid)) {
      final cached = _profileCache[uid]!;
      if (DateTime.now().difference(cached.lastLogin) < _cacheExpiry) {
        return cached;
      }
    }
    
    // Fetch fresh data
    final profile = await EnhancedAuthService().getCurrentUserProfile();
    if (profile != null) {
      _profileCache[uid] = profile;
    }
    
    return profile;
  }
}
```

### Error Handling Best Practices
```dart
class AuthErrorHandler {
  static void handleAuthError(BuildContext context, String error) {
    switch (error) {
      case 'No account found with this email address':
        _showErrorDialog(
          context,
          'Account Not Found',
          'We couldn\'t find an account with that email. Would you like to register?',
          actions: [
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: Text('Register'),
            ),
          ],
        );
        break;
        
      case 'Incorrect password. Please try again':
        _showErrorDialog(
          context,
          'Incorrect Password',
          'The password you entered is incorrect. Please try again or reset your password.',
          actions: [
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/reset-password'),
              child: Text('Reset Password'),
            ),
          ],
        );
        break;
        
      default:
        _showErrorDialog(
          context,
          'Authentication Error',
          error,
        );
    }
  }
  
  static void _showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    List<Widget>? actions,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: actions ?? [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

## Testing

### Unit Tests
```dart
void main() {
  group('EnhancedAuthService Tests', () {
    late EnhancedAuthService authService;
    
    setUp(() {
      authService = EnhancedAuthService();
    });
    
    test('Email validation', () {
      expect(authService._isValidEmail('test@example.com'), true);
      expect(authService._isValidEmail('invalid-email'), false);
    });
    
    test('Password validation', () {
      expect(authService._isValidPassword('123456'), true);
      expect(authService._isValidPassword('123'), false);
    });
    
    test('Role checking', () async {
      // Mock user profile
      when(authService.getCurrentUserProfile())
          .thenAnswer(UserProfile(/* mock data */));
      
      expect(await authService.isCustomer, true);
      expect(await authService.isDriver, false);
    });
  });
}
```

### Integration Tests
```dart
void main() {
  integrationTest('Authentication Flow', (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(MyApp());
    
    // Test registration
    await tester.tap(find.text('Register'));
    await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
    await tester.enterText(find.byKey(Key('password_field')), 'password123');
    await tester.enterText(find.byKey(Key('confirm_field')), 'password123');
    await tester.tap(find.text('Sign Up'));
    
    await tester.pumpAndSettle();
    
    // Verify navigation to home
    expect(find.text('Welcome'), findsOneWidget);
  });
}
```

## Troubleshooting

### Common Issues

**Authentication Not Working:**
- Check Firebase configuration in `google-services.json`
- Verify SHA-1 and SHA-256 keys in Firebase Console
- Ensure internet connectivity
- Check Firebase Authentication is enabled

**Role-Based Access Not Working:**
- Verify Firestore security rules
- Check user profile data structure
- Ensure role is set during registration
- Test role checking methods

**Session Persistence Issues:**
- Check Flutter Secure Storage permissions
- Verify secure storage is properly initialized
- Test "Remember Me" functionality
- Clear app data and test again

**Social Sign-In Issues:**
- Verify OAuth configuration in Firebase Console
- Check bundle IDs and package names
- Ensure redirect URIs are configured
- Test with different social accounts

This comprehensive authentication system provides enterprise-grade security with proper role management, persistent sessions, and production-ready error handling that will significantly enhance your taxi booking application's security and user experience.
