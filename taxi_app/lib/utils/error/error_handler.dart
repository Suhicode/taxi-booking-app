// lib/services/error_handler.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

/// Error types for comprehensive error handling
enum ErrorType {
  network,
  location,
  gps,
  permission,
  api,
  runtime,
  validation,
  timeout,
  server,
}

/// Error severity levels
enum ErrorSeverity {
  low,      // Informational, user can continue
  medium,    // Warning, functionality limited
  high,      // Error, feature unavailable
  critical,   // Critical, app may crash
}

/// Custom error class with user-friendly messages
class AppError {
  final ErrorType type;
  final ErrorSeverity severity;
  final String title;
  final String message;
  final String? technicalDetails;
  final String? action;
  final dynamic originalError;
  final DateTime timestamp;
  final String? errorCode;

  const AppError({
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.technicalDetails,
    this.action,
    this.originalError,
    this.errorCode,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AppError.network({
    required String message,
    String? technicalDetails,
    dynamic originalError,
  }) {
    return AppError(
      type: ErrorType.network,
      severity: ErrorSeverity.high,
      title: 'Connection Error',
      message: message,
      technicalDetails: technicalDetails,
      action: 'Check your internet connection and try again',
      originalError: originalError,
    );
  }

  factory AppError.location({
    required String message,
    String? technicalDetails,
    dynamic originalError,
  }) {
    return AppError(
      type: ErrorType.location,
      severity: ErrorSeverity.high,
      title: 'Location Error',
      message: message,
      technicalDetails: technicalDetails,
      action: 'Enable location services and try again',
      originalError: originalError,
    );
  }

  factory AppError.gps({
    required String message,
    String? technicalDetails,
    dynamic originalError,
  }) {
    return AppError(
      type: ErrorType.gps,
      severity: ErrorSeverity.high,
      title: 'GPS Error',
      message: message,
      technicalDetails: technicalDetails,
      action: 'Enable GPS in device settings',
      originalError: originalError,
    );
  }

  factory AppError.permission({
    required String message,
    String? technicalDetails,
    dynamic originalError,
  }) {
    return AppError(
      type: ErrorType.permission,
      severity: ErrorSeverity.high,
      title: 'Permission Denied',
      message: message,
      technicalDetails: technicalDetails,
      action: 'Grant required permissions in app settings',
      originalError: originalError,
    );
  }

  factory AppError.api({
    required String message,
    String? technicalDetails,
    int? statusCode,
    dynamic originalError,
  }) {
    return AppError(
      type: ErrorType.api,
      severity: ErrorSeverity.medium,
      title: 'API Error',
      message: message,
      technicalDetails: technicalDetails,
      action: 'Try again in a few moments',
      originalError: originalError,
      errorCode: statusCode?.toString(),
    );
  }

  factory AppError.runtime({
    required String message,
    String? technicalDetails,
    dynamic originalError,
  }) {
    return AppError(
      type: ErrorType.runtime,
      severity: ErrorSeverity.critical,
      title: 'Unexpected Error',
      message: message,
      technicalDetails: technicalDetails,
      action: 'Restart the app if the problem persists',
      originalError: originalError,
    );
  }

  factory AppError.timeout({
    required String message,
    String? technicalDetails,
    dynamic originalError,
  }) {
    return AppError(
      type: ErrorType.timeout,
      severity: ErrorSeverity.medium,
      title: 'Request Timeout',
      message: message,
      technicalDetails: technicalDetails,
      action: 'Check your connection and try again',
      originalError: originalError,
    );
  }

  factory AppError.server({
    required String message,
    String? technicalDetails,
    int? statusCode,
    dynamic originalError,
  }) {
    return AppError(
      type: ErrorType.server,
      severity: ErrorSeverity.high,
      title: 'Server Error',
      message: message,
      technicalDetails: technicalDetails,
      action: 'Try again later or contact support',
      originalError: originalError,
      errorCode: statusCode?.toString(),
    );
  }

  /// Get user-friendly action based on error type
  String get userAction {
    switch (type) {
      case ErrorType.network:
        return 'Check your internet connection';
      case ErrorType.location:
        return 'Enable location services';
      case ErrorType.gps:
        return 'Turn on GPS in settings';
      case ErrorType.permission:
        return 'Grant permissions in settings';
      case ErrorType.api:
        return 'Try again in a moment';
      case ErrorType.runtime:
        return 'Restart the app';
      case ErrorType.timeout:
        return 'Check connection and retry';
      case ErrorType.server:
        return 'Try again later';
      case ErrorType.validation:
        return 'Check your input';
      default:
        return 'Try again';
    }
  }

  /// Get appropriate icon for error type
  IconData get icon {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.location:
        return Icons.location_off;
      case ErrorType.gps:
        return Icons.gps_off;
      case ErrorType.permission:
        return Icons.lock;
      case ErrorType.api:
        return Icons.cloud_off;
      case ErrorType.runtime:
        return Icons.error_outline;
      case ErrorType.timeout:
        return Icons.timer_off;
      case ErrorType.server:
        return Icons.dns;
      case ErrorType.validation:
        return Icons.warning;
      default:
        return Icons.error;
    }
  }

  /// Get appropriate color for error severity
  Color get color {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.blue;
      case ErrorSeverity.medium:
        return Colors.orange;
      case ErrorSeverity.high:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }
}

/// Comprehensive error handler service
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final Connectivity _connectivity = Connectivity();
  final List<AppError> _errorHistory = [];
  final StreamController<AppError> _errorStreamController = StreamController<AppError>.broadcast();

  /// Error stream for UI components
  Stream<AppError> get errorStream => _errorStreamController.stream;

  /// Get error history for debugging
  List<AppError> get errorHistory => List.unmodifiable(_errorHistory);

  /// Handle network connectivity errors
  static Future<T> handleNetworkErrors<T>(
    Future<T> Function() operation, {
    String? operationName,
    Duration? timeout,
    int? retryCount,
  }) async {
    int attempts = 0;
    final maxRetries = retryCount ?? 3;

    while (attempts < maxRetries) {
      try {
        // Check connectivity first
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult == ConnectivityResult.none) {
          throw AppError.network(
            message: 'No internet connection available',
            technicalDetails: 'Connectivity check returned: ${connectivityResult}',
          );
        }

        // Execute operation with timeout
        final result = timeout != null
            ? await operation().timeout(timeout)
            : await operation();

        return result;
      } on SocketException catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          throw AppError.network(
            message: 'Network connection failed after $maxRetries attempts',
            technicalDetails: e.message,
            originalError: e,
          );
        }
        await Future.delayed(Duration(seconds: attempts * 2)); // Exponential backoff
      } on TimeoutException catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          throw AppError.timeout(
            message: 'Operation timed out after $maxRetries attempts',
            technicalDetails: e.message,
            originalError: e,
          );
        }
        await Future.delayed(Duration(seconds: attempts * 2));
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          throw AppError.network(
            message: 'Network operation failed: ${e.toString()}',
            technicalDetails: 'Operation: ${operationName ?? 'Unknown'}',
            originalError: e,
          );
        }
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }

    throw AppError.network(
      message: 'All $maxRetries retry attempts failed',
      technicalDetails: 'Operation: ${operationName ?? 'Unknown'}',
    );
  }

  /// Handle location service errors
  static Future<T> handleLocationErrors<T>(
    Future<T> Function() operation, {
    bool requestPermission = true,
  }) async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw AppError.gps(
          message: 'Location services are disabled on this device',
          technicalDetails: 'LocationServiceEnabled: $serviceEnabled',
        );
      }

      // Request permission if needed
      if (requestPermission) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          final requestedPermission = await Geolocator.requestPermission();
          if (requestedPermission == LocationPermission.denied) {
            throw AppError.permission(
              message: 'Location permission was denied',
              technicalDetails: 'LocationPermission: $requestedPermission',
            );
          } else if (requestedPermission == LocationPermission.deniedForever) {
            throw AppError.permission(
              message: 'Location permission is permanently denied',
              technicalDetails: 'User must enable in app settings',
            );
          }
        } else if (permission == LocationPermission.deniedForever) {
          throw AppError.permission(
            message: 'Location permission is permanently denied',
            technicalDetails: 'User must enable in app settings',
          );
        }
      }

      // Execute location operation
      return await operation();
    } on LocationServiceDisabledException catch (e) {
      throw AppError.gps(
        message: 'Location services are disabled',
        technicalDetails: e.message,
        originalError: e,
      );
    } on PermissionDeniedException catch (e) {
      throw AppError.permission(
        message: 'Location permission denied',
        technicalDetails: e.message,
        originalError: e,
      );
    } catch (e) {
      throw AppError.location(
        message: 'Failed to get location: ${e.toString()}',
        technicalDetails: 'Location operation failed',
        originalError: e,
      );
    }
  }

  /// Handle API request errors
  static Future<T> handleApiErrors<T>(
    Future<T> Function() operation, {
    String? apiEndpoint,
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    try {
      final result = timeout != null
          ? await operation().timeout(timeout)
          : await operation();

      return result;
    } on http.ClientException catch (e) {
      throw AppError.api(
        message: 'Network request failed: ${e.message}',
        technicalDetails: 'API: ${apiEndpoint ?? 'Unknown'}',
        originalError: e,
      );
    } on SocketException catch (e) {
      throw AppError.network(
        message: 'Socket connection failed: ${e.message}',
        technicalDetails: 'API: ${apiEndpoint ?? 'Unknown'}',
        originalError: e,
      );
    } on TimeoutException catch (e) {
      throw AppError.timeout(
        message: 'API request timed out',
        technicalDetails: 'API: ${apiEndpoint ?? 'Unknown'}',
        originalError: e,
      );
    } on FormatException catch (e) {
      throw AppError.api(
        message: 'Invalid API response format',
        technicalDetails: e.message,
        originalError: e,
      );
    } catch (e) {
      throw AppError.api(
        message: 'API request failed: ${e.toString()}',
        technicalDetails: 'API: ${apiEndpoint ?? 'Unknown'}',
        originalError: e,
      );
    }
  }

  /// Handle runtime errors with fallback
  static T handleRuntimeErrors<T>(
    T Function() operation, {
    T? fallback,
    String? operationName,
  }) {
    try {
      return operation();
    } on FormatException catch (e) {
      ErrorHandler.logError(AppError.runtime(
        message: 'Data format error: ${e.message}',
        technicalDetails: 'Operation: ${operationName ?? 'Unknown'}',
        originalError: e,
      ));
      return fallback ?? (throw e);
    } on RangeError catch (e) {
      ErrorHandler.logError(AppError.runtime(
        message: 'Index out of bounds: ${e.message}',
        technicalDetails: 'Operation: ${operationName ?? 'Unknown'}',
        originalError: e,
      ));
      return fallback ?? (throw e);
    } on TypeError catch (e) {
      ErrorHandler.logError(AppError.runtime(
        message: 'Type error: ${e.toString()}',
        technicalDetails: 'Operation: ${operationName ?? 'Unknown'}',
        originalError: e,
      ));
      return fallback ?? (throw e);
    } on StateError catch (e) {
      ErrorHandler.logError(AppError.runtime(
        message: 'State error: ${e.message}',
        technicalDetails: 'Operation: ${operationName ?? 'Unknown'}',
        originalError: e,
      ));
      return fallback ?? (throw e);
    } catch (e) {
      ErrorHandler.logError(AppError.runtime(
        message: 'Unexpected error: ${e.toString()}',
        technicalDetails: 'Operation: ${operationName ?? 'Unknown'}',
        originalError: e,
      ));
      return fallback ?? (throw e);
    }
  }

  /// Log error for debugging and analytics
  static void logError(AppError error) {
    _instance._errorHistory.add(error);
    
    // Keep only last 100 errors
    if (_instance._errorHistory.length > 100) {
      _instance._errorHistory.removeAt(0);
    }

    // Send to error stream
    _instance._errorStreamController.add(error);

    // Log to console in debug mode
    if (kDebugMode) {
      print('ERROR: ${error.title} - ${error.message}');
      if (error.technicalDetails != null) {
        print('Details: ${error.technicalDetails}');
      }
      print('Timestamp: ${error.timestamp}');
      if (error.originalError != null) {
        print('Original: ${error.originalError}');
      }
    }

    // In production, send to analytics/crashlytics
    if (!kDebugMode) {
      // TODO: Integrate with Firebase Crashlytics or similar
      // FirebaseCrashlytics.instance.recordError(
      //   error.originalError,
      //   fatal: error.severity == ErrorSeverity.critical,
      //   information: [
      //     DiagnosticsProperty('error_type', error.type.name),
      //     DiagnosticsProperty('error_severity', error.severity.name),
      //     DiagnosticsProperty('error_code', error.errorCode),
      //   ],
      // );
    }
  }

  /// Get user-friendly error message for display
  static String getUserMessage(AppError error) {
    switch (error.type) {
      case ErrorType.network:
        if (error.message.contains('No internet')) {
          return 'You\'re offline. Please check your internet connection.';
        } else if (error.message.contains('timeout')) {
          return 'Connection timed out. Please try again.';
        } else {
          return 'Network error. Please check your connection and try again.';
        }
      case ErrorType.location:
        if (error.message.contains('permission')) {
          return 'Location permission is required. Please enable it in settings.';
        } else if (error.message.contains('disabled')) {
          return 'Please enable location services in your device settings.';
        } else {
          return 'Unable to get your location. Please try again.';
        }
      case ErrorType.gps:
        return 'GPS is turned off. Please enable it in settings.';
      case ErrorType.permission:
        return 'Permission required. Please grant access in app settings.';
      case ErrorType.api:
        if (error.errorCode == '401') {
          return 'Session expired. Please log in again.';
        } else if (error.errorCode == '403') {
          return 'Access denied. Please contact support.';
        } else if (error.errorCode == '404') {
          return 'Service not found. Please try again later.';
        } else if (error.errorCode == '500') {
          return 'Server error. Please try again in a few minutes.';
        } else {
          return 'Service temporarily unavailable. Please try again.';
        }
      case ErrorType.runtime:
        return 'Something went wrong. Please restart the app.';
      case ErrorType.timeout:
        return 'Request timed out. Please check your connection.';
      case ErrorType.server:
        return 'Server is experiencing issues. Please try again later.';
      case ErrorType.validation:
        return 'Please check your input and try again.';
      default:
        return error.message;
    }
  }

  /// Show error dialog to user
  static void showErrorDialog(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              error.icon,
              color: error.color,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error.title,
                style: TextStyle(
                  color: error.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ErrorHandler.getUserMessage(error),
              style: const TextStyle(fontSize: 16),
            ),
            if (error.action != null) ...[
              const SizedBox(height: 8),
              Text(
                'Suggestion: ${error.action}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (kDebugMode && error.technicalDetails != null) ...[
              const SizedBox(height: 8),
              Text(
                'Technical details: ${error.technicalDetails}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar for less critical errors
  static void showErrorSnackBar(
    BuildContext context,
    AppError error, {
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error.icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ErrorHandler.getUserMessage(error),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: error.color,
        duration: duration,
        action: error.action != null
            ? SnackBarAction(
                label: 'Fix',
                textColor: Colors.white,
                onPressed: () {
                  // Handle action based on error type
                  _handleErrorAction(context, error);
                },
              )
            : null,
      ),
    );
  }

  /// Handle error action (open settings, etc.)
  static void _handleErrorAction(BuildContext context, AppError error) {
    switch (error.type) {
      case ErrorType.permission:
        // Open app settings
        openAppSettings();
        break;
      case ErrorType.location:
      case ErrorType.gps:
        // Open location settings
        openLocationSettings();
        break;
      default:
        // Do nothing for other types
        break;
    }
  }

  /// Open app settings
  static Future<void> openAppSettings() async {
    // This would require platform-specific implementation
    // For now, just show a message
    if (kDebugMode) {
      print('Opening app settings...');
    }
  }

  /// Open location settings
  static Future<void> openLocationSettings() async {
    // This would require platform-specific implementation
    // For now, just show a message
    if (kDebugMode) {
      print('Opening location settings...');
    }
  }

  /// Clear error history
  void clearErrorHistory() {
    _errorHistory.clear();
  }

  /// Get error statistics
  Map<ErrorType, int> getErrorStatistics() {
    final stats = <ErrorType, int>{};
    for (final error in _errorHistory) {
      stats[error.type] = (stats[error.type] ?? 0) + 1;
    }
    return stats;
  }

  /// Dispose resources
  void dispose() {
    _errorStreamController.close();
  }
}

/// Error boundary widget for catching errors in the widget tree
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(AppError)? errorBuilder;
  final void Function(AppError)? onError;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorBuilder,
    this.onError,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  AppError? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ??
          _DefaultErrorWidget(error: _error!);
    }
    
    return ErrorWidget.builder(
      error: FlutterError(''),
      child: widget.child,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _error = null;
  }

  void _handleError(AppError error) {
    setState(() {
      _error = error;
    });
    
    widget.onError?.call(error);
    ErrorHandler.logError(error);
  }
}

/// Default error widget
class _DefaultErrorWidget extends StatelessWidget {
  final AppError error;

  const _DefaultErrorWidget({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                error.icon,
                size: 64,
                color: error.color,
              ),
              const SizedBox(height: 16),
              Text(
                error.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: error.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ErrorHandler.getUserMessage(error),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _restartApp(),
                icon: const Icon(Icons.refresh),
                label: const Text('Restart App'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: error.color,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _restartApp() {
    // In a real app, this would restart the app
    if (kDebugMode) {
      print('Restarting app...');
    }
  }
}
