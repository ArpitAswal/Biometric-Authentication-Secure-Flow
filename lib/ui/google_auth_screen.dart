import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';

class GoogleAuthScreen extends StatelessWidget {
  const GoogleAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Authentication'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Consumer<AuthViewModel>(
            builder: (context, viewModel, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.g_mobiledata,
                    size: 100,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Google Login',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Demonstrating biometric flow after third-party OAuth sign-in.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 48),
                  if (viewModel.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton.icon(
                      onPressed: () async {
                        final success = await viewModel.loginWithGoogle();
                        if (!success &&
                            context.mounted &&
                            viewModel.errorMessage.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(viewModel.errorMessage),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        } else if (success && context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(
                        Icons.g_mobiledata,
                        size: 32,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
