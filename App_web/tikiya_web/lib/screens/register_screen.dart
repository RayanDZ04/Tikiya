import 'package:flutter/material.dart';

/// Auth screens are intentionally disabled for the static-only web launch.
///
/// The app will re-enable login/register when the backend API is deployed.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "Inscription temporairement indisponible.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
