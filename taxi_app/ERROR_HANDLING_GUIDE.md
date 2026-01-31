# Robust Error Handling Guide

## Overview
The `ErrorHandler` service provides comprehensive error handling that ensures your Flutter app never crashes and displays user-friendly messages for all common scenarios including network issues, location problems, permission denials, and runtime errors.

## Key Features

### 🌐 **Network Error Handling**
- **Connectivity Detection**: Automatic internet connection checking
- **Retry Logic**: Exponential backoff with configurable retry attempts
- **Timeout Management**: Configurable timeouts for all operations
- **Offline Support**: Graceful degradation when offline
- **Network Type Detection**: WiFi vs Cellular handling

### 📍 **Location Error Handling**
- **GPS Status**: Check if location services are enabled
- **Permission Management**: Request and handle location permissions
- **Location Settings**: Direct users to device settings when needed
- **Fallback Options**: Alternative location methods when GPS fails
- **Privacy Compliance**: Respect user privacy choices

### 🔐 **Permission Error Handling**
- **Permission Detection**: Check all required permissions
- **User Guidance**: Clear instructions for granting permissions
- **Settings Integration**: Direct users to app settings
- **Graceful Degradation**: Limited functionality without permissions
- **Permission Caching**: Remember user permission choices

### 🔄 **API Error Handling**
- **HTTP Status Codes**: Proper handling of all HTTP responses
- **Timeout Protection**: Prevent hanging requests
- **Rate Limiting**: Handle API rate limits gracefully
- **Server Errors**: User-friendly server error messages
- **Data Validation**: Validate API responses

### ⚡ **Runtime Error Handling**
- **Exception Catching**: Comprehensive exception handling
- **Error Boundaries**: Widget-level error catching
- **Fallback Values**: Safe defaults when operations fail
- **State Recovery**: Automatic state restoration
- **Memory Safety**: Prevent memory leaks from errors

## Quick Usage Examples

### Network Error Handling
```dart
import 'package:your_app/services/error_handler.dart';

// Safe API call with retry logic
final result = await ErrorHandler.handleNetworkErrors(
  () async {
    final response = await http.get(Uri.parse('https://api.example.com/data'));
    return json.decode(response.body);
  },
  operationName: 'Fetch user data',
  timeout: Duration(seconds: 10),
  retryCount: 3,
);

// Result is safely returned or throws AppError
```

### Location Error Handling
```dart
// Safe location access with permission handling
final position = await ErrorHandler.handleLocationErrors(
  () async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  },
  requestPermission: true,
);

// Position is returned or AppError is thrown
```

### API Error Handling
```dart
// Safe API request with comprehensive error handling
final data = await ErrorHandler.handleApiErrors(
  () async {
    final response = await http.post(
      Uri.parse('https://api.example.com/ride'),
      body: json.encode(rideData),
      headers: {'Content-Type': 'application/json'},
    );
    return json.decode(response.body);
  },
  apiEndpoint: 'Create Ride',
  timeout: Duration(seconds: 15),
);
```

### Runtime Error Handling
```dart
// Safe data parsing with fallback
final parsedData = ErrorHandler.handleRuntimeErrors(
  () => json.decode(rawData),
  fallback: {},
  operationName: 'Parse ride data',
);

// Safe array access
final item = ErrorHandler.handleRuntimeErrors(
  () => items[index],
  fallback: null,
  operationName: 'Get ride item',
);
```

### Error Display in UI
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchData(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error as AppError;
          
          // Show error dialog for critical errors
          if (error.severity == ErrorSeverity.critical) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ErrorHandler.showErrorDialog(context, error);
            });
          }
          
          // Show error snackbar for less critical errors
          return ErrorDisplayWidget(error: error);
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingWidget();
        }
        
        return DataWidget(data: snapshot.data);
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
  connectivity_plus: ^5.0.1
  geolocator: ^10.1.0
  permission_handler: ^11.1.0
  http: ^0.13.6
```

### 2. Wrap App with Error Boundary
```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onError: (error) {
        // Log error for analytics
        ErrorHandler.logError(error);
        
        // Show user-friendly message
        ErrorHandler.showErrorSnackBar(context, error);
      },
      child: MaterialApp(
        home: HomeScreen(),
      ),
    );
  }
}
```

### 3. Replace Unsafe Operations
```dart
// Before
final position = await Geolocator.getCurrentPosition();

// After
final position = await ErrorHandler.handleLocationErrors(
  () => Geolocator.getCurrentPosition(),
);

// Before
final response = await http.get(url);

// After
final response = await ErrorHandler.handleNetworkErrors(
  () => http.get(url),
);
```

### 4. Add Error Monitoring
```dart
class ErrorMonitor extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ErrorHandler().errorStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final error = snapshot.data!;
          
          // Update UI based on error severity
          switch (error.severity) {
            case ErrorSeverity.critical:
              return CriticalErrorBanner(error: error);
            case ErrorSeverity.high:
              return ErrorBanner(error: error);
            case ErrorSeverity.medium:
              return WarningBanner(error: error);
            default:
              return const SizedBox.shrink();
          }
        }
        
        return const SizedBox.shrink();
      },
    );
  }
}
```

## Advanced Features

### Custom Error Types
```dart
// Create custom error for your app
class RideError extends AppError {
  final String? rideId;
  final String? driverId;

  const RideError({
    required ErrorType type,
    required String message,
    this.rideId,
    this.driverId,
  }) : super(
          type: type,
          severity: ErrorSeverity.high,
          title: 'Ride Error',
          message: message,
        );

  @override
  String get userAction {
    if (rideId != null) {
      return 'Contact support about ride #$rideId';
    }
    return super.userAction;
  }
}

// Use custom error
throw RideError(
  type: ErrorType.api,
  message: 'Driver not available for this ride',
  rideId: '12345',
);
```

### Error Recovery Strategies
```dart
class ErrorRecovery {
  static Future<T?> attemptRecovery<T>({
    required AppError error,
    required Future<T> Function() retryOperation,
    int maxAttempts = 3,
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await retryOperation();
      } catch (e) {
        if (attempt == maxAttempts) {
          // Final attempt failed, return null
          return null;
        }
        
        // Wait before retry
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    return null;
  }
}
```

### Error Analytics
```dart
class ErrorAnalytics {
  static void trackError(AppError error) {
    // Send to analytics service
    AnalyticsService.logEvent('app_error', {
      'error_type': error.type.name,
      'error_severity': error.severity.name,
      'error_message': error.message,
      'error_code': error.errorCode,
      'timestamp': error.timestamp.toIso8601String(),
    });
    
    // Track error patterns
    _trackErrorPattern(error);
  }
  
  static void _trackErrorPattern(AppError error) {
    final stats = ErrorHandler().getErrorStatistics();
    
    // Check for error spikes
    if (stats[error.type] != null && stats[error.type]! > 10) {
      AnalyticsService.logEvent('error_spike', {
        'error_type': error.type.name,
        'count': stats[error.type],
      });
    }
  }
}
```

### User Experience Improvements
```dart
class UserExperienceHelper {
  static Widget buildErrorWidget(AppError error) {
    switch (error.severity) {
      case ErrorSeverity.critical:
        return CriticalErrorWidget(
          title: error.title,
          message: ErrorHandler.getUserMessage(error),
          action: error.userAction,
          onRetry: () => _handleRetry(error),
        );
        
      case ErrorSeverity.high:
        return ErrorWidget(
          icon: error.icon,
          message: ErrorHandler.getUserMessage(error),
          color: error.color,
        );
        
      case ErrorSeverity.medium:
        return WarningWidget(
          message: ErrorHandler.getUserMessage(error),
        );
        
      default:
        return InfoWidget(
          message: ErrorHandler.getUserMessage(error),
        );
    }
  }
  
  static void _handleRetry(AppError error) {
    switch (error.type) {
      case ErrorType.network:
        // Retry network operation
        break;
      case ErrorType.location:
        // Request location again
        break;
      case ErrorType.api:
        // Retry API call
        break;
      default:
        // Show help screen
        break;
    }
  }
}
```

## Production Considerations

### Error Reporting
```dart
class ProductionErrorReporter {
  static Future<void> reportError(AppError error) async {
    // Send to error tracking service
    await ErrorTrackingService.reportError(
      error: error.originalError?.toString(),
      stackTrace: StackTrace.current,
      information: [
        DiagnosticsProperty('error_type', error.type.name),
        DiagnosticsProperty('error_severity', error.severity.name),
        DiagnosticsProperty('user_message', error.message),
        DiagnosticsProperty('timestamp', error.timestamp.toIso8601String()),
      ],
    );
    
    // Store in local error log
    await _storeErrorLocally(error);
  }
  
  static Future<void> _storeErrorLocally(AppError error) async {
    final prefs = await SharedPreferences.getInstance();
    final errors = prefs.getStringList('error_log') ?? [];
    
    errors.add(json.encode({
      'type': error.type.name,
      'message': error.message,
      'timestamp': error.timestamp.toIso8601String(),
    }));
    
    // Keep only last 50 errors
    if (errors.length > 50) {
      errors.removeRange(0, errors.length - 50);
    }
    
    await prefs.setStringList('error_log', errors);
  }
}
```

### Performance Monitoring
```dart
class PerformanceMonitor {
  static void monitorOperation<T>({
    required String operationName,
    required Future<T> operation,
    Duration? timeout,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation;
      stopwatch.stop();
      
      // Log performance metrics
      AnalyticsService.logEvent('operation_performance', {
        'operation': operationName,
        'duration_ms': stopwatch.elapsedMilliseconds,
        'success': true,
      });
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      // Log failed operation
      AnalyticsService.logEvent('operation_performance', {
        'operation': operationName,
        'duration_ms': stopwatch.elapsedMilliseconds,
        'success': false,
        'error': e.toString(),
      });
      
      rethrow;
    }
  }
}
```

## Testing

### Error Simulation
```dart
class ErrorSimulator {
  static Future<void> testNetworkErrors() async {
    // Test no internet
    await ErrorHandler.handleNetworkErrors(
      () async {
        throw SocketException('No internet connection');
      },
    );
    
    // Test timeout
    await ErrorHandler.handleNetworkErrors(
      () async {
        await Future.delayed(Duration(seconds: 10));
        throw TimeoutException('Request timed out', null);
      },
      timeout: Duration(seconds: 5),
    );
  }
  
  static Future<void> testLocationErrors() async {
    // Test permission denied
    await ErrorHandler.handleLocationErrors(
      () async {
        throw PermissionDeniedException('Location permission denied');
      },
    );
    
    // Test GPS disabled
    await ErrorHandler.handleLocationErrors(
      () async {
        throw LocationServiceDisabledException('GPS disabled');
      },
    );
  }
}
```

### Integration Tests
```dart
void main() {
  group('Error Handling Tests', () {
    testWidgets('Network error handling', (tester) async {
      await tester.pumpWidget(ErrorBoundary(
        child: TestWidget(),
      ));
      
      // Simulate network error
      // Test that error is caught and displayed
      expect(find.text('Connection Error'), findsOneWidget);
    });
    
    testWidgets('Location error handling', (tester) async {
      await tester.pumpWidget(ErrorBoundary(
        child: LocationWidget(),
      ));
      
      // Test location permission error
      expect(find.text('Permission Denied'), findsOneWidget);
    });
  });
}
```

## Troubleshooting

### Common Error Handling Issues

**Errors Still Crashing App:**
- Ensure ErrorBoundary wraps the entire widget tree
- Check that all async operations are wrapped in error handlers
- Verify error handlers don't throw exceptions
- Test error recovery mechanisms

**User Messages Not Friendly:**
- Customize ErrorHandler.getUserMessage() for your app
- Add context-specific error messages
- Test error messages with real users
- Ensure action suggestions are helpful

**Performance Issues:**
- Monitor error handling overhead
- Optimize error logging for production
- Use efficient error recovery strategies
- Avoid excessive error notifications

**Missing Error Types:**
- Add custom error types for your domain
- Extend AppError class with specific fields
- Create specialized error handlers
- Update error display components

This comprehensive error handling system ensures your Flutter app provides a smooth, professional user experience even when things go wrong, with proper error recovery, user-friendly messages, and robust fallback mechanisms.
