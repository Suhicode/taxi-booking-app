import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  AppUser? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Initialize auth state
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Listen to auth state changes
      _authService.authStateChanges.listen((firebaseUser) async {
        if (firebaseUser != null) {
          // User is signed in
          _user = await _getOrCreateUser(firebaseUser);
        } else {
          // User is signed out
          _user = null;
        }
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _authService.signInWithEmailAndPassword(email, password);
      _user = await _getOrCreateUser(userCredential.user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register with email and password
  Future<bool> registerWithEmailAndPassword(
    String email, 
    String password, 
    String displayName,
    String userType,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _authService.registerWithEmailAndPassword(email, password);
      
      // Update display name
      await userCredential.user?.updateDisplayName(displayName);
      
      // Create user profile
      _user = AppUser.fromFirebaseUser(
        userCredential.user!,
        userType: userType,
      ).copyWith(
        displayName: displayName,
      );
      
      // Save user to Firestore
      await _saveUserToFirestore(_user!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _authService.signInWithGoogle();
      _user = await _getOrCreateUser(userCredential.user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign in with Facebook
  Future<bool> signInWithFacebook() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _authService.signInWithFacebook();
      _user = await _getOrCreateUser(userCredential.user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign in with Apple
  Future<bool> signInWithApple() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _authService.signInWithApple();
      _user = await _getOrCreateUser(userCredential.user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
    } catch (e) {
      _error = e.toString();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (displayName != null || photoURL != null) {
        await _authService.updateProfile(
          displayName: displayName,
          photoURL: photoURL,
        );
      }

      if (_user != null) {
        _user = _user!.copyWith(
          displayName: displayName ?? _user!.displayName,
          photoURL: photoURL ?? _user!.photoURL,
          phoneNumber: phoneNumber ?? _user!.phoneNumber,
        );
        
        await _saveUserToFirestore(_user!);
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Helper method to get or create user in Firestore
  Future<AppUser> _getOrCreateUser(User firebaseUser) async {
    final firestore = FirebaseFirestore.instance;
    
    try {
      // Try to get user from Firestore
      final doc = await firestore.collection('users').doc(firebaseUser.uid).get();
      
      if (doc.exists) {
        // User exists in Firestore
        return AppUser.fromMap(doc.data()!);
      } else {
        // Create new user in Firestore
        final newUser = AppUser.fromFirebaseUser(firebaseUser);
        await _saveUserToFirestore(newUser);
        return newUser;
      }
    } catch (e) {
      // If there's an error, return a basic user object
      return AppUser.fromFirebaseUser(firebaseUser);
    }
  }

  // Save user to Firestore
  Future<void> _saveUserToFirestore(AppUser user) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('users').doc(user.id).set(user.toMap());
  }
}
