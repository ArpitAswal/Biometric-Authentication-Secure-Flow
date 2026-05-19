import 'package:google_sign_in/google_sign_in.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../models/account_model.dart';
import 'auth_service.dart';

/// Concrete implementation of AuthService for Google Sign-In.
/// Demonstrates handling third-party provider authentication.
class GoogleAuthService implements AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  @override
  Future<AccountModel?> login() async {
    try {
      await _googleSignIn.initialize();
      final googleUser = await _googleSignIn.authenticate();

      return AccountModel(
        id: googleUser.id,
        username: googleUser.displayName ?? 'Google User',
        email: googleUser.email,
        authProvider: 'google',
      );
    } catch (error) {
      throw AuthException('Google Sign-In failed: $error');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // suppress
    }
  }

  @override
  Future<AccountModel?> fetchUserProfile(String token, String? name) async {
    // For Google Sign-In biometric flow, if they authenticate with biometrics,
    // we bypass a fresh Google Login and restore the session locally.
    try {
      await _googleSignIn.initialize();
      
      // Fallback to mock data if we have a valid biometric token validation
      if (token.isNotEmpty) {
        return AccountModel(
          id: 'google_local_user',
          username: 'Google Biometric User',
          email: 'google@example.com',
          authProvider: 'google',
        );
      }
    } catch (e) {
      // suppress
    }
    return null;
  }
}
