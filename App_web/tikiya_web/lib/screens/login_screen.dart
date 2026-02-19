import 'package:flutter/material.dart';

/// Auth screens are intentionally disabled for the static-only web launch.
///
/// The app will re-enable login/register when the backend API is deployed.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Connexion temporairement indisponible.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
