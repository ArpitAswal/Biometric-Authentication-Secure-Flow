import '../../models/account_model.dart';

/// Interface representing authentication operations.
/// Demonstrates the Interface Segregation Principle (SOLID).
abstract class AuthService {
  /// Authenticates and returns a user token or AccountModel
  Future<AccountModel?> login();
  
  /// Logs the user out
  Future<void> logout();
  
  /// Fetches a user profile given a previously saved token
  Future<AccountModel?> fetchUserProfile(String token, String? username);
}
