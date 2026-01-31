// lib/utils/constants/route_constants.dart
class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String bookRide = '/book-ride';
  static const String rideHistory = '/ride-history';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String driverHome = '/driver-home';
  static const String driverEarnings = '/driver-earnings';
  static const String driverProfile = '/driver-profile';
  static const String driverSettings = '/driver-settings';
  static const String rideTracking = '/ride-tracking';
  static const String rideCompletion = '/ride-completion';
  static const String rideRating = '/ride-rating';
  static const String adminDashboard = '/admin-dashboard';
  static const String userManagement = '/user-management';
  static const String analytics = '/analytics';
  static const String help = '/help';

  static Map<String, String> get routes => {
    splash: splash,
    login: login,
    register: register,
    home: home,
    bookRide: bookRide,
    rideHistory: rideHistory,
    profile: profile,
    settings: settings,
    driverHome: driverHome,
    driverEarnings: driverEarnings,
    driverProfile: driverProfile,
    driverSettings: driverSettings,
    rideTracking: rideTracking,
    rideCompletion: rideCompletion,
    rideRating: rideRating,
    adminDashboard: adminDashboard,
    userManagement: userManagement,
    analytics: analytics,
    help: help,
  };
}
