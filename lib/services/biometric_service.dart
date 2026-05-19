import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';


/// Singleton service responsible for interfacing with the device's
/// biometric authentication hardware (Face ID, Touch ID, etc.).
class BiometricService {
  // Singleton pattern implementation
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if the device has biometric hardware and if it's enrolled.
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }

  }

  /// Triggers the native biometric prompt to authenticate the user.
  /// Returns [true] if authentication was successful, [false] otherwise.
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        persistAcrossBackgrounding: true, // Keep the prompt open if the app goes to the background
        biometricOnly: false, // Fallback to device PIN if biometric fails
      );
    } on PlatformException catch (e) {
      debugPrint('Error during biometric authentication: $e');
      return false;
    }

  }
}
