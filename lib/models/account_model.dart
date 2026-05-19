/// Models a user account, representing the current logged-in user or stored credentials.
class AccountModel {
  final String id;
  final String username; // Or name
  final String email;
  final String authProvider; // 'email' or 'google'

  AccountModel({
    required this.id,
    required this.username,
    required this.email,
    this.authProvider = 'email',
  });

  // Factory to create a user account from JSON data
  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String,
      username: json['username'] ?? json['name'] ?? '',
      email: json['email'] as String,
      authProvider: json['authProvider'] ?? 'email',
    );
  }

  // Converts the AccountModel object back to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'authProvider': authProvider,
    };
  }
}
