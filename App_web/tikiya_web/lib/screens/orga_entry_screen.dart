import 'package:flutter/material.dart';

import '../services/session_store.dart';
import 'orga_home_screen.dart';
import 'orga_public_landing_screen.dart';

class OrgaEntryScreen extends StatelessWidget {
  final SessionStore sessionStore;

  const OrgaEntryScreen({super.key, required this.sessionStore});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: sessionStore.user(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator()),
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return OrgaPublicLandingScreen(
            onLogin: () => Navigator.of(context).pushNamed('/orga-login'),
            onRegister: () => Navigator.of(context).pushNamed('/orga-register'),
            onNeeds: () => Navigator.of(context).pushNamed('/orga-needs'),
          );
        }

        final role = user.role;
        final isOrganizer = role == 'organizer' || role == 'organisateur';
        if (!isOrganizer) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            Navigator.of(context).pushReplacementNamed('/participant');
          });
          return const Scaffold(
            body: Center(
              child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator()),
            ),
          );
        }

        return OrgaHomeScreen(sessionStore: sessionStore);
      },
    );
  }
}
