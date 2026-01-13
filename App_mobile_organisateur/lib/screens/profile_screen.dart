import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/l10n.dart';
import '../services/session_store.dart';
import '../widgets/bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const bleuProfond = Color(0xFF1A237E);
    const bleuCyan = Color(0xFF00ACC1);

    final session = SessionStore.I.session.value;

    return Scaffold(
      backgroundColor: bleuProfond,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE0E0E0)),
              boxShadow: const [BoxShadow(color: Color.fromRGBO(26, 35, 126, 0.10), blurRadius: 24, offset: Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: l10n.appTitle,
                        style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.w700, color: bleuProfond),
                      ),
                      TextSpan(
                        text: '!',
                        style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.w800, color: bleuCyan),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.navProfile,
                  style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: bleuProfond),
                ),
                const SizedBox(height: 16),
                if (session == null)
                  Text('Non connecté', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600))
                else ...[
                  _kv('Email', session.email),
                  _kv('Rôle', session.role ?? ''),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: bleuCyan, foregroundColor: Colors.white),
                      onPressed: () {
                        SessionStore.I.clear();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      icon: const Icon(Icons.logout),
                      label: Text(l10n.authLogout, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(current: 'profile'),
    );
  }
}

Widget _kv(String k, String v) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 80, child: Text(k, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700))),
        Expanded(child: Text(v, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600))),
      ],
    ),
  );
}
