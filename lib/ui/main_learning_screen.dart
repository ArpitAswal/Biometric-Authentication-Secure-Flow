import 'package:flutter/material.dart';
import 'email_auth_screen.dart';
import 'google_auth_screen.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';

class MainLearningScreen extends StatelessWidget {
  const MainLearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Auth Integration'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.fingerprint, size: 80, color: Color(0xFF6C63FF)),
              const SizedBox(height: 24),
              const Text(
                'Mastering Biometrics',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How it works in the real world:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Initialization: App checks if device supports biometrics via `local_auth` package.\n'
                      '2. First Login: User logs in manually with Email or Social Auth (e.g. Google).\n'
                      '3. Token Save: Upon success, a secure token/session ID is stored securely (using Keystore/Secure Enclave) via `flutter_secure_storage`.\n'
                      '4. Opt-In: User enables Biometric Login, setting a flag.\n'
                      '5. Subsequent Logins: App prompts FaceID/Fingerprint. If success, app retrieves the secure token and validates it with the backend.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Select Authentication Flow',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmailAuthScreen()),
                  );
                },
                icon: const Icon(Icons.email),
                label: const Text('Email/Password Biometric Auth'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GoogleAuthScreen()),
                  );
                },
                icon: const Icon(Icons.g_mobiledata, size: 32),
                label: const Text('Google Sign-In Biometric Auth'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // If biometric is enabled from a past session, allow direct login
              Consumer<AuthViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.canUseBiometricLogin) {
                    final providerIsGoogle =
                        viewModel.savedAuthProvider == 'google';
                    final displayName =
                        viewModel.savedDisplayName ?? 'Saved Account';
                    final email = viewModel.savedEmail ?? '';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 16),

                        // Account identity card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[800]!),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: providerIsGoogle
                                    ? Colors.white
                                    : const Color(0xFF6C63FF),
                                child: providerIsGoogle
                                    ? const Icon(
                                        Icons.g_mobiledata,
                                        size: 30,
                                        color: Colors.black,
                                      )
                                    : Text(
                                        displayName
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (email.isNotEmpty)
                                      Text(
                                        email,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                providerIsGoogle
                                    ? Icons.verified
                                    : Icons.email_outlined,
                                color: providerIsGoogle
                                    ? Colors.blue
                                    : Colors.grey,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        OutlinedButton.icon(
                          onPressed: () async {
                            final success = await viewModel
                                .loginWithBiometrics();
                            if (!success &&
                                context.mounted &&
                                viewModel.errorMessage.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(viewModel.errorMessage),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('Quick Biometric Sign-In'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            side: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Forget Saved Account'),
                                content: Text(
                                  'Remove saved credentials for "$displayName"? '
                                  'You will need to sign in manually next time.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Forget',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await viewModel.removeAccountFromDevice();
                            }
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.grey,
                          ),
                          label: const Text(
                            'Forget Saved Account',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
