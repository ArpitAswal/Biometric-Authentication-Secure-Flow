import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../models/account_model.dart';
import 'auth_service.dart';

/// Concrete implementation of AuthService for Google Sign-In.
///
/// WHY serverClientId is required in v7 on Android:
/// google_sign_in v7 switched to the new Google Identity Services SDK on Android.
/// Unlike v6, it does NOT automatically read the Web Client ID from
/// google-services.json metadata. You must pass it explicitly.
///
/// HOW to find your Web Client ID:
/// 1. Open Firebase Console → your project → Authentication → Sign-in method → Google.
/// 2. Expand the "Web SDK configuration" section.
/// 3. Copy the "Web client ID" (ends with .apps.googleusercontent.com).
///    It is also listed in google-services.json under
///    oauth_client → client_type: 3.
class GoogleAuthService implements AuthService {
  /// Your Web Client ID from Firebase Console.
  /// ⚠️ In a real production app, load this from a secrets manager or
  /// compile-time env variable (e.g. --dart-define) so it is not
  /// hardcoded in source control.
  static const String _webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  @override
  Future<AccountModel?> login() async {
    if (_webClientId.isEmpty) {
      throw AuthException(
        'Google Web Client ID is not configured.\n'
        'Please build/run the application with --dart-define or --dart-define-from-file.\n'
        'Example:\n'
        'flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=your_client_id_here',
      );
    }
    try {
      // v7 API: initialize() MUST receive the serverClientId on Android.
      // On iOS/macOS it reads the CLIENT_ID from GoogleService-Info.plist, so
      // passing serverClientId here is harmless on those platforms.
      await _googleSignIn.initialize(serverClientId: _webClientId);

      final googleUser = await _googleSignIn.authenticate();

      return AccountModel(
        id: googleUser.id,
        username: googleUser.displayName ?? 'Google User',
        email: googleUser.email,
        authProvider: 'google',
      );
    } catch (error) {
      debugPrint('GoogleAuthService.login error: $error');
      throw AuthException('Google Sign-In failed: $error');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // suppress — sign-out errors should not block the app
      throw AuthException("Google Sign-out failed: ${e.toString()}");
    }
  }

  @override
  Future<AccountModel?> fetchUserProfile(
    String token,
    String? savedEmail, {
    String? displayName,
  }) async {
    // Biometric restore path: the OS already verified the device owner.
    // We reconstruct the AccountModel from credentials persisted in
    // Secure Storage — no extra Google network round-trip needed.
    try {
      if (token.isNotEmpty && savedEmail != null && savedEmail.isNotEmpty) {
        return AccountModel(
          id: 'google_${savedEmail.hashCode}',
          username: displayName ?? savedEmail.split('@')[0],
          email: savedEmail,
          authProvider: 'google',
        );
      }
    } catch (e) {
      debugPrint('GoogleAuthService.fetchUserProfile error: $e');
    }
    return null;
  }
}
