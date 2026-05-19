import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../services/auth/email_auth_service.dart';
import '../services/auth/google_auth_service.dart';
import '../services/auth/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/secure_storage_service.dart';

/// ViewModel managing the authentication state and business logic.
/// Utilizes the Provider package for state management and demonstrates MVVM.
class AuthViewModel extends ChangeNotifier {
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final BiometricService _biometricService = BiometricService();
  final SecureStorageService _secureStorageService = SecureStorageService();

  AccountModel? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isBiometricAvailable = false;
  bool _canUseBiometricLogin = false; 

  AccountModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isBiometricAvailable => _isBiometricAvailable;
  bool get canUseBiometricLogin => _canUseBiometricLogin;

  /// Initializes the ViewModel by checking biometric availability and previous login state.
  Future<void> checkBiometricAvailability() async {
    _isBiometricAvailable = await _biometricService.isBiometricAvailable();
    
    if (_isBiometricAvailable) {
      final savedUsername = await _secureStorageService.getUsername();
      final isEnabled = await _secureStorageService.isBiometricEnabled();
      
      if (savedUsername != null && savedUsername.isNotEmpty && isEnabled) {
        _canUseBiometricLogin = true;
      } else {
        _canUseBiometricLogin = false;
      }
    }
    notifyListeners();
  }

  /// Attempts to log the user in using email and password.
  Future<bool> loginWithEmail(String email, String password) async {
    _setLoading(true);
    _errorMessage = '';

    try {
      final service = EmailAuthService(email, password);
      final user = await service.login();

      if (user != null) {
        await _handleSuccessfulLogin(user, 'email');
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Invalid email or password';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Attempts to log the user in using Google Sign-In.
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _errorMessage = '';

    try {
      final user = await _googleAuthService.login();

      if (user != null) {
        await _handleSuccessfulLogin(user, 'google');
        _setLoading(false);
        return true;
      } else {
        // User probably cancelled the flow
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> _handleSuccessfulLogin(AccountModel user, String provider) async {
    // Security Check: If a DIFFERENT user logs in, we must invalidate the old biometric token
    final savedUsername = await _secureStorageService.getUsername();
    if (savedUsername != null && savedUsername != user.email) {
      await _secureStorageService.deleteToken();
      await _secureStorageService.setBiometricEnabled(false);
      _canUseBiometricLogin = false;
    }

    _currentUser = user;
    
    // Save secure data for future biometric sign-ins
    await _secureStorageService.saveToken('${provider}_dummy_secure_token_${user.id}');
    await _secureStorageService.saveUsername(user.email);
    
    // Check if they previously enabled biometrics
    await checkBiometricAvailability();
  }

  /// Attempts to log the user in using biometric authentication.
  Future<bool> loginWithBiometrics() async {
    _setLoading(true);
    _errorMessage = '';

    try {
      final authenticated = await _biometricService.authenticate(
        localizedReason: 'Please authenticate to sign in securely',
      );

      if (authenticated) {
        final token = await _secureStorageService.getToken();

        if (token != null) {
          AuthService authService;
          if (token.startsWith('google_')) {
             authService = _googleAuthService;
          } else {
             authService = EmailAuthService('', ''); // Dummy credentials for fetch profile
          }
          final username = await _secureStorageService.getUsername();
          final user = await authService.fetchUserProfile(token, username);
          if (user != null) {
            _currentUser = user;
            _setLoading(false);
            return true;
          } else {
            _errorMessage = 'Session expired. Please log in manually.';
          }
        } else {
          _errorMessage = 'No credentials found. Please log in manually.';
        }
      } else {
        _errorMessage = 'Biometric authentication failed or was cancelled.';
      }
    } catch (e) {
      _errorMessage = 'Biometric Failed: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
    return false;
  }

  /// Toggles the user's preference for using biometric sign-in.
  Future<void> toggleBiometricPreference(bool enable) async {
    await _secureStorageService.setBiometricEnabled(enable);
    await checkBiometricAvailability();
  }

  /// Logs the user out of the current session, but keeps biometric credentials intact (soft logout)
  Future<void> logout() async {
    if (_currentUser?.authProvider == 'google') {
      await _googleAuthService.logout();
    }

    // Clear active in-memory session
    _currentUser = null;
    
    // Keep credentials and biometric preference in secure storage
    // to allow quick biometric login next time.
    
    notifyListeners();
  }

  /// Completely removes the account from this device (hard logout).
  Future<void> removeAccountFromDevice() async {
    _setLoading(true);
    try {
      if (_currentUser?.authProvider == 'google') {
        await _googleAuthService.logout();
      }
      _currentUser = null;
      
      // Clear all stored credentials and flags
      await _secureStorageService.deleteToken();
      await _secureStorageService.deleteUsername();
      await _secureStorageService.setBiometricEnabled(false);
      _canUseBiometricLogin = false;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
