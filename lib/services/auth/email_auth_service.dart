import '../../core/network/dio_client.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../models/account_model.dart';
import 'auth_service.dart';

/// Concrete implementation of AuthService for Email/Password login.
/// Uses DioClient to demonstrate API communication.
class EmailAuthService implements AuthService {
  final String email;
  final String password;
  final DioClient _dioClient = DioClient();

  EmailAuthService(this.email, this.password);

  @override
  Future<AccountModel?> login() async {
    try {
      final response = await _dioClient.post('/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
      return AccountModel(
        id: data['id'],
        username: data['name'],
        email: data['email'],
        authProvider: 'email',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    // Optionally call a logout endpoint.
    // For now, it's handled locally.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<AccountModel?> fetchUserProfile(String token, String? name) async {
    // In a real app, this makes a GET request using the JWT token
    // e.g. _dioClient.get('/profile', headers: {'Authorization': 'Bearer $token'});
    await Future.delayed(const Duration(seconds: 1));
    if (token.isNotEmpty) {
       return AccountModel(
        id: '12345',
        username: 'Returning ${name?.split('@')[0].toString()}',
        email: 'user@example.com',
        authProvider: 'email',
      );
    }
    return null;
  }
}
