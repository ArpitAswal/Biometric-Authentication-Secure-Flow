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

  // Saved identity info for the "Quick Sign-In" prompt on the login screen.
  // Populated during checkBiometricAvailability() after a soft logout.
  String? _savedEmail;
  String? _savedDisplayName;
  String? _savedAuthProvider; // 'email' | 'google'

  AccountModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isBiometricAvailable => _isBiometricAvailable;
  bool get canUseBiometricLogin => _canUseBiometricLogin;

  // Expose saved identity so the UI can show e.g.
  // "Sign in as john@gmail.com using biometrics"
  String? get savedEmail => _savedEmail;
  String? get savedDisplayName => _savedDisplayName;
  String? get savedAuthProvider => _savedAuthProvider;

  // ─── Initialisation ────────────────────────────────────────────────────────

  /// Checks hardware capability and loads previously persisted identity info.
  /// Called once at startup and after every successful login / logout.
  Future<void> checkBiometricAvailability() async {
    _isBiometricAvailable = await _biometricService.isBiometricAvailable();

    if (_isBiometricAvailable) {
      final savedUsername = await _secureStorageService.getUsername();
      final isEnabled = await _secureStorageService.isBiometricEnabled();

      if (savedUsername != null && savedUsername.isNotEmpty && isEnabled) {
        _canUseBiometricLogin = true;

        // Load the full identity so the login screen can greet the user.
        _savedEmail = savedUsername;
        _savedDisplayName = await _secureStorageService.getDisplayName();
        _savedAuthProvider = await _secureStorageService.getAuthProvider();
      } else {
        _canUseBiometricLogin = false;
        _savedEmail = null;
        _savedDisplayName = null;
        _savedAuthProvider = null;
      }
    }
    notifyListeners();
  }

  // ─── Login flows ───────────────────────────────────────────────────────────

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
        // User probably cancelled the flow.
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Biometric login – the full real-world flow:
  ///
  /// 1. Preference check → did this user opt-in to biometric login?
  /// 2. OS prompt        → fingerprint / face scan via `local_auth`.
  /// 3. Token retrieval  → decrypt token from Secure Storage (only possible
  ///                       after the OS grants access).
  /// 4. Provider detect  → read saved provider to pick the right AuthService.
  /// 5. Profile restore  → rebuild AccountModel from saved identity values.
  ///
  /// Edge-cases handled:
  /// - Biometric preference disabled       → guard before showing OS prompt.
  /// - Token missing after successful scan → force manual re-login.
  /// - Stale/expired token                 → clean up and force manual re-login.
  /// - Google vs email provider            → correct AuthService chosen.
  Future<bool> loginWithBiometrics() async {
    _setLoading(true);
    _errorMessage = '';

    try {
      // Guard: preference must be enabled (user opted-in from Settings).
      if (!_canUseBiometricLogin) {
        _errorMessage =
            'Biometric login is not enabled. Please enable it in Settings.';
        return false;
      }

      final authenticated = await _biometricService.authenticate(
        localizedReason: 'Unlock your screen with PIN, pattern, password, face or fingerprint',
      );

      if (!authenticated) {
        _errorMessage = 'Biometric authentication failed or was cancelled.';
        return false;
      }

      // Scan succeeded – read the token that was stored behind the biometric lock.
      final token = await _secureStorageService.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'No saved session found. Please log in manually.';
        // Wipe stale preference so the UI reflects the actual state.
        await _secureStorageService.setBiometricEnabled(false);
        _canUseBiometricLogin = false;
        return false;
      }

      // Read all persisted identity values.
      final savedEmail = await _secureStorageService.getUsername();
      final displayName = await _secureStorageService.getDisplayName();
      final authProvider = await _secureStorageService.getAuthProvider();

      // Choose the right service based on the persisted provider.
      AuthService authService;
      if (authProvider == 'google') {
        authService = _googleAuthService;
      } else {
        // Default to email for 'email' or any unknown/legacy provider.
        authService = EmailAuthService('', '');
      }

      final user = await authService.fetchUserProfile(
        token,
        savedEmail,
        displayName: displayName,
      );

      if (user != null) {
        _currentUser = user;
        return true;
      } else {
        // Token is stale (expired / revoked on the server).
        _errorMessage = 'Session expired. Please log in manually.';
        // Clean up so the user is not stuck in a broken biometric-only state.
        await _secureStorageService.deleteToken();
        await _secureStorageService.setBiometricEnabled(false);
        _canUseBiometricLogin = false;
      }
    } catch (e) {
      _errorMessage = 'Biometric failed: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
    return false;
  }

  // ─── Post-login common handling ────────────────────────────────────────────

  Future<void> _handleSuccessfulLogin(
    AccountModel user,
    String provider,
  ) async {
    // Security check: if a DIFFERENT user logs in, invalidate the old biometric
    // credentials immediately so User A cannot biometric-log-in as User B.
    final savedUsername = await _secureStorageService.getUsername();
    if (savedUsername != null && savedUsername != user.email) {
      await _secureStorageService.deleteToken();
      await _secureStorageService.deleteDisplayName();
      await _secureStorageService.deleteAuthProvider();
      await _secureStorageService.setBiometricEnabled(false);
      _canUseBiometricLogin = false;
    }

    _currentUser = user;

    // Persist the full identity for biometric restoration.
    await _secureStorageService.saveToken(
      '${provider}_secure_token_${user.id}',
    );
    await _secureStorageService.saveUsername(user.email);
    await _secureStorageService.saveDisplayName(user.username);
    await _secureStorageService.saveAuthProvider(provider);

    // Re-evaluate biometric availability with fresh credentials.
    await checkBiometricAvailability();
  }

  // ─── Settings ──────────────────────────────────────────────────────────────

  /// Toggles the user's preference for using biometric sign-in.
  Future<void> toggleBiometricPreference(bool enable) async {
    await _secureStorageService.setBiometricEnabled(enable);
    await checkBiometricAvailability();
  }

  // ─── Logout flows ──────────────────────────────────────────────────────────

  /// Soft logout – ends the in-memory session but keeps credentials in Secure
  /// Storage so the user can sign back in with biometrics next time.
  ///
  /// For Google: calls googleSignIn.signOut() to release the SDK's in-memory
  /// auth state only. The token in Secure Storage is intentionally kept so
  /// biometric login can reconstruct the session without a new OAuth round-trip.
  Future<void> logout() async {
    if (_currentUser?.authProvider == 'google') {
      // Release the Google SDK's in-memory state only – Secure Storage is kept.
      await _googleAuthService.logout();
    }
    _currentUser = null;

    // Refresh so the login screen shows the correct biometric state.
    await checkBiometricAvailability();
  }

  /// Hard logout – completely removes all credentials from this device.
  ///
  /// Edge-cases handled:
  /// - Called from Dashboard (user is logged in):  _currentUser is available.
  /// - Called from Login screen (after soft-logout): _currentUser is null, so
  ///   we read the saved provider from Secure Storage to correctly decide
  ///   whether to call googleSignIn.signOut().
  Future<void> removeAccountFromDevice() async {
    _setLoading(true);
    try {
      // Determine provider even when _currentUser is null (post soft-logout).
      final provider =
          _currentUser?.authProvider ??
          await _secureStorageService.getAuthProvider();

      if (provider == 'google') {
        // Revoke the Google OAuth session from the Google SDK completely.
        await _googleAuthService.logout();
      }

      _currentUser = null;

      // Delete every persisted credential and preference.
      await _secureStorageService.deleteToken();
      await _secureStorageService.deleteUsername();
      await _secureStorageService.deleteDisplayName();
      await _secureStorageService.deleteAuthProvider();
      await _secureStorageService.setBiometricEnabled(false);

      _canUseBiometricLogin = false;
      _savedEmail = null;
      _savedDisplayName = null;
      _savedAuthProvider = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
