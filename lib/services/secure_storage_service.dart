import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Singleton service to handle secure storage operations using flutter_secure_storage.
/// This follows the SOLID principles (Single Responsibility Principle) where
/// it solely manages local secure storage of tokens or sensitive data.
class SecureStorageService {
  // Singleton pattern implementation
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  // Use the most secure options available in flutter_secure_storage
  // Android: encryptedSharedPreferences prevents adb backup extraction.
  // iOS: KeychainAccessibility.passcode binds the item to the device passcode and
  //   invalidates it if the passcode is removed.
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.passcode),
  );

  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'saved_username';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _authProviderKey = 'auth_provider'; // 'email' | 'google'
  static const String _displayNameKey =
      'saved_display_name'; // The user's real display name

  /// Save the authentication token securely
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Read the stored authentication token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Delete the token (e.g., on logout)
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Save the username for future biometric sign-ins
  Future<void> saveUsername(String username) async {
    await _storage.write(key: _usernameKey, value: username);
  }

  /// Read the saved username
  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  /// Clear username on logout if needed
  Future<void> deleteUsername() async {
    await _storage.delete(key: _usernameKey);
  }

  /// Set the biometric preference status for the account
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  /// Get the biometric preference status
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  /// Save the auth provider used on the last successful login (e.g. 'email' or 'google')
  Future<void> saveAuthProvider(String provider) async {
    await _storage.write(key: _authProviderKey, value: provider);
  }

  /// Read the saved auth provider
  Future<String?> getAuthProvider() async {
    return await _storage.read(key: _authProviderKey);
  }

  /// Delete the saved auth provider
  Future<void> deleteAuthProvider() async {
    await _storage.delete(key: _authProviderKey);
  }

  /// Save the user's display name (used to show on the login screen after soft-logout)
  Future<void> saveDisplayName(String name) async {
    await _storage.write(key: _displayNameKey, value: name);
  }

  /// Read the saved display name
  Future<String?> getDisplayName() async {
    return await _storage.read(key: _displayNameKey);
  }

  /// Delete the saved display name
  Future<void> deleteDisplayName() async {
    await _storage.delete(key: _displayNameKey);
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
