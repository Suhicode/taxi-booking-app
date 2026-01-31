// lib/services/enhanced_auth_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// User roles for the taxi application
enum UserRole {
  customer,
  driver,
  admin,
}

/// Authentication result with user role and profile
class AuthResult {
  final UserCredential? credential;
  final String? errorMessage;
  final UserRole? role;
  final UserProfile? profile;

  const AuthResult({
    this.credential,
    this.errorMessage,
    this.role,
    this.profile,
  });

  bool get isSuccess => credential != null && errorMessage == null;
  bool get isCustomer => role == UserRole.customer;
  bool get isDriver => role == UserRole.driver;
  bool get isAdmin => role == UserRole.admin;
}

/// User profile with role-specific data
class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final UserRole role;
  final DateTime createdAt;
  final DateTime lastLogin;
  final Map<String, dynamic> roleData;

  const UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.role,
    required this.createdAt,
    required this.lastLogin,
    this.roleData = const {},
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      photoURL: data['photoURL'] as String?,
      role: UserRole.values.firstWhere(
        (role) => role.name == data['role'],
        orElse: () => UserRole.customer,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLogin: (data['lastLogin'] as Timestamp).toDate(),
      roleData: data['roleData'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'roleData': roleData,
    };
  }
}

/// Authentication exceptions with proper error handling
class AuthException implements Exception {
  final String code;
  final String message;
  final String? details;

  const AuthException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'AuthException($code): $message${details != null ? ' - $details' : ''}';
}

/// Enhanced authentication service with role-based access and security
class EnhancedAuthService {
  static final EnhancedAuthService _instance = EnhancedAuthService._internal();
  factory EnhancedAuthService() => _instance;
  EnhancedAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookAuth _facebookAuth = FacebookAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  /// Initialize the auth service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Set up auth state listener
    _auth.authStateChanges().listen(_onAuthStateChanged);
    
    // Check for existing session
    await _checkExistingSession();
  }

  /// Get current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Get current user profile from Firestore
  Future<UserProfile?> getCurrentUserProfile() async {
    if (_auth.currentUser == null) return null;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw AuthException(
        code: 'PROFILE_FETCH_ERROR',
        message: 'Failed to fetch user profile',
        details: e.toString(),
      );
    }
  }

  /// Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Check if current user has specific role
  Future<bool> hasRole(UserRole role) async {
    final profile = await getCurrentUserProfile();
    return profile?.role == role;
  }

  /// Check if current user is customer
  Future<bool> get isCustomer async => await hasRole(UserRole.customer);

  /// Check if current user is driver
  Future<bool> get isDriver async => await hasRole(UserRole.driver);

  /// Check if current user is admin
  Future<bool> get isAdmin async => await hasRole(UserRole.admin);

  /// Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        return const AuthResult(
          errorMessage: 'Email and password are required',
        );
      }

      if (!_isValidEmail(email)) {
        return const AuthResult(
          errorMessage: 'Please enter a valid email address',
        );
      }

      if (password.length < 6) {
        return const AuthResult(
          errorMessage: 'Password must be at least 6 characters',
        );
      }

      // Attempt sign in
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save session if remember me is checked
      if (rememberMe) {
        await _saveSession(email, password);
      }

      // Update last login
      await _updateLastLogin(credential.user!.uid);

      // Get user profile
      final profile = await getCurrentUserProfile();

      return AuthResult(
        credential: credential,
        role: profile?.role,
        profile: profile,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        errorMessage: _getFirebaseAuthErrorMessage(e),
      );
    } catch (e) {
      return AuthResult(
        errorMessage: 'An unexpected error occurred',
        details: e.toString(),
      );
    }
  }

  /// Register new user with email and password
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String confirmPassword,
    required String displayName,
    UserRole role = UserRole.customer,
    Map<String, dynamic>? roleData,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        return const AuthResult(
          errorMessage: 'All fields are required',
        );
      }

      if (!_isValidEmail(email)) {
        return const AuthResult(
          errorMessage: 'Please enter a valid email address',
        );
      }

      if (password.length < 6) {
        return const AuthResult(
          errorMessage: 'Password must be at least 6 characters',
        );
      }

      if (password != confirmPassword) {
        return const AuthResult(
          errorMessage: 'Passwords do not match',
        );
      }

      if (displayName.isEmpty) {
        return const AuthResult(
          errorMessage: 'Display name is required',
        );
      }

      // Create user account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);

      // Create user profile in Firestore
      final userProfile = UserProfile(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
        role: role,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        roleData: roleData ?? {},
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userProfile.toFirestore());

      return AuthResult(
        credential: credential,
        role: role,
        profile: userProfile,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        errorMessage: _getFirebaseAuthErrorMessage(e),
      );
    } catch (e) {
      return AuthResult(
        errorMessage: 'Registration failed',
        details: e.toString(),
      );
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle({UserRole role = UserRole.customer}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const AuthResult(
          errorMessage: 'Google sign in was cancelled',
        );
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final authCredential = await _auth.signInWithCredential(credential);

      // Check if user exists in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(authCredential.user!.uid)
          .get();

      UserProfile? profile;
      
      if (!userDoc.exists) {
        // Create new user profile
        profile = UserProfile(
          uid: authCredential.user!.uid,
          email: authCredential.user!.email!,
          displayName: authCredential.user!.displayName ?? 'Google User',
          photoURL: authCredential.user!.photoURL,
          role: role,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(authCredential.user!.uid)
            .set(profile.toFirestore());
      } else {
        profile = UserProfile.fromFirestore(userDoc);
        await _updateLastLogin(authCredential.user!.uid);
      }

      return AuthResult(
        credential: authCredential,
        role: profile?.role,
        profile: profile,
      );
    } catch (e) {
      return AuthResult(
        errorMessage: 'Google sign in failed',
        details: e.toString(),
      );
    }
  }

  /// Sign in with Facebook
  Future<AuthResult> signInWithFacebook({UserRole role = UserRole.customer}) async {
    try {
      final LoginResult result = await _facebookAuth.login();
      
      if (result.status != LoginStatus.success) {
        return const AuthResult(
          errorMessage: 'Facebook login failed',
        );
      }

      final OAuthCredential facebookAuthCredential = 
          FacebookAuthProvider.credential(result.accessToken!.token);
      
      final authCredential = await _auth.signInWithCredential(facebookAuthCredential);

      // Similar to Google sign in - check/create profile
      final userDoc = await _firestore
          .collection('users')
          .doc(authCredential.user!.uid)
          .get();

      UserProfile? profile;
      
      if (!userDoc.exists) {
        profile = UserProfile(
          uid: authCredential.user!.uid,
          email: authCredential.user!.email!,
          displayName: authCredential.user!.displayName ?? 'Facebook User',
          photoURL: authCredential.user!.photoURL,
          role: role,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(authCredential.user!.uid)
            .set(profile.toFirestore());
      } else {
        profile = UserProfile.fromFirestore(userDoc);
        await _updateLastLogin(authCredential.user!.uid);
      }

      return AuthResult(
        credential: authCredential,
        role: profile?.role,
        profile: profile,
      );
    } catch (e) {
      return AuthResult(
        errorMessage: 'Facebook sign in failed',
        details: e.toString(),
      );
    }
  }

  /// Sign in with Apple
  Future<AuthResult> signInWithApple({UserRole role = UserRole.customer}) async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final authCredential = await _auth.signInWithCredential(oauthCredential);

      // Similar to other sign in methods
      final userDoc = await _firestore
          .collection('users')
          .doc(authCredential.user!.uid)
          .get();

      UserProfile? profile;
      
      if (!userDoc.exists) {
        profile = UserProfile(
          uid: authCredential.user!.uid,
          email: authCredential.user!.email ?? 'apple@user.com',
          displayName: appleCredential.givenName ?? 'Apple User',
          role: role,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(authCredential.user!.uid)
            .set(profile.toFirestore());
      } else {
        profile = UserProfile.fromFirestore(userDoc);
        await _updateLastLogin(authCredential.user!.uid);
      }

      return AuthResult(
        credential: authCredential,
        role: profile?.role,
        profile: profile,
      );
    } catch (e) {
      return AuthResult(
        errorMessage: 'Apple sign in failed',
        details: e.toString(),
      );
    }
  }

  /// Sign out and clean up session
  Future<void> signOut() async {
    try {
      // Sign out from all providers
      await _googleSignIn.signOut();
      await _facebookAuth.logOut();
      await _auth.signOut();

      // Clear secure storage
      await _secureStorage.deleteAll();
      
      // Clear shared preferences
      await _prefs?.clear();
      
      // Clear any cached data
      await _clearCachedData();
    } catch (e) {
      throw AuthException(
        code: 'SIGNOUT_ERROR',
        message: 'Failed to sign out properly',
        details: e.toString(),
      );
    }
  }

  /// Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      if (!_isValidEmail(email)) {
        return const AuthResult(
          errorMessage: 'Please enter a valid email address',
        );
      }

      await _auth.sendPasswordResetEmail(email: email);
      
      return const AuthResult(
        credential: null, // Success but no credential needed
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        errorMessage: _getFirebaseAuthErrorMessage(e),
      );
    } catch (e) {
      return AuthResult(
        errorMessage: 'Failed to send reset email',
        details: e.toString(),
      );
    }
  }

  /// Update user profile
  Future<AuthResult> updateProfile({
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? roleData,
  }) async {
    try {
      if (_auth.currentUser == null) {
        return const AuthResult(
          errorMessage: 'No user is currently signed in',
        );
      }

      // Update Firebase Auth profile
      if (displayName != null) {
        await _auth.currentUser?.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await _auth.currentUser?.updatePhotoURL(photoURL);
      }

      // Update Firestore profile
      final currentProfile = await getCurrentUserProfile();
      if (currentProfile != null) {
        final updatedProfile = UserProfile(
          uid: currentProfile.uid,
          email: currentProfile.email,
          displayName: displayName ?? currentProfile.displayName,
          photoURL: photoURL ?? currentProfile.photoURL,
          role: currentProfile.role,
          createdAt: currentProfile.createdAt,
          lastLogin: DateTime.now(),
          roleData: roleData ?? currentProfile.roleData,
        );

        await _firestore
            .collection('users')
            .doc(currentProfile.uid)
            .update(updatedProfile.toFirestore());
      }

      return const AuthResult(
        credential: null,
      );
    } catch (e) {
      return AuthResult(
        errorMessage: 'Failed to update profile',
        details: e.toString(),
      );
    }
  }

  /// Change password
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (_auth.currentUser == null) {
        return const AuthResult(
          errorMessage: 'No user is currently signed in',
        );
      }

      if (newPassword.length < 6) {
        return const AuthResult(
          errorMessage: 'New password must be at least 6 characters',
        );
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: _auth.currentUser!.email!,
        password: currentPassword,
      );

      await _auth.currentUser!.reauthenticateWithCredential(credential);
      
      // Update password
      await _auth.currentUser!.updatePassword(newPassword);

      return const AuthResult(
        credential: null,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        errorMessage: _getFirebaseAuthErrorMessage(e),
      );
    } catch (e) {
      return AuthResult(
        errorMessage: 'Failed to change password',
        details: e.toString(),
      );
    }
  }

  /// Delete user account
  Future<AuthResult> deleteAccount() async {
    try {
      if (_auth.currentUser == null) {
        return const AuthResult(
          errorMessage: 'No user is currently signed in',
        );
      }

      // Delete user profile from Firestore
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .delete();

      // Delete Firebase Auth user
      await _auth.currentUser!.delete();

      // Clean up session
      await signOut();

      return const AuthResult(
        credential: null,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        errorMessage: _getFirebaseAuthErrorMessage(e),
      );
    } catch (e) {
      return AuthResult(
        errorMessage: 'Failed to delete account',
        details: e.toString(),
      );
    }
  }

  /// Private helper methods

  /// Handle auth state changes
  void _onAuthStateChanged(User? user) {
    if (user != null) {
      _updateLastLogin(user.uid);
    }
  }

  /// Check for existing session
  Future<void> _checkExistingSession() async {
    try {
      final savedEmail = await _secureStorage.read(key: 'saved_email');
      final savedPassword = await _secureStorage.read(key: 'saved_password');
      
      if (savedEmail != null && savedPassword != null) {
        // Auto sign in with saved credentials
        await signInWithEmailAndPassword(
          email: savedEmail,
          password: savedPassword,
          rememberMe: true,
        );
      }
    } catch (e) {
      // Clear corrupted session data
      await _secureStorage.deleteAll();
    }
  }

  /// Save session securely
  Future<void> _saveSession(String email, String password) async {
    await _secureStorage.write(key: 'saved_email', value: email);
    await _secureStorage.write(key: 'saved_password', value: password);
  }

  /// Update last login timestamp
  Future<void> _updateLastLogin(String uid) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .update({'lastLogin': Timestamp.fromDate(DateTime.now())});
  }

  /// Clear cached data
  Future<void> _clearCachedData() async {
    // Clear any app-specific cached data
    await _prefs?.remove('cached_driver_data');
    await _prefs?.remove('cached_ride_history');
    await _prefs?.remove('cached_user_preferences');
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Get user-friendly Firebase Auth error messages
  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'wrong-password':
        return 'Incorrect password. Please try again';
      case 'email-already-in-use':
        return 'An account with this email already exists';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}

/// Authentication state management for Flutter widgets
class AuthProvider extends ChangeNotifier {
  final EnhancedAuthService _authService = EnhancedAuthService();
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _userProfile != null;
  bool get isCustomer => _userProfile?.role == UserRole.customer;
  bool get isDriver => _userProfile?.role == UserRole.driver;
  bool get isAdmin => _userProfile?.role == UserRole.admin;

  /// Initialize auth provider
  Future<void> initialize() async {
    await _authService.initialize();
    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        _userProfile = await _authService.getCurrentUserProfile();
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );

      if (result.isSuccess) {
        _userProfile = result.profile;
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage!);
        return false;
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Register new user
  Future<bool> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String displayName,
    UserRole role = UserRole.customer,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        displayName: displayName,
        role: role,
      );

      if (result.isSuccess) {
        _userProfile = result.profile;
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage!);
        return false;
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle({UserRole role = UserRole.customer}) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInWithGoogle(role: role);
      
      if (result.isSuccess) {
        _userProfile = result.profile;
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage!);
        return false;
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      await _authService.signOut();
      _userProfile = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.sendPasswordResetEmail(email);
      
      if (result.isSuccess) {
        return true;
      } else {
        _setError(result.errorMessage!);
        return false;
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Update profile
  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
      
      if (result.isSuccess) {
        _userProfile = await _authService.getCurrentUserProfile();
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage!);
        return false;
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
