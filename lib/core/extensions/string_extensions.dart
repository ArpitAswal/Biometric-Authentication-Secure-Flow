// Extension methods demonstrating Dart extensions
extension StringValidationExtension on String {
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    return emailRegex.hasMatch(this);
  }

  bool get isValidPassword {
    return length >= 6;
  }
}
