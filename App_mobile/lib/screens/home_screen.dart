import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '_placeholders.dart';
import '../services/session_store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _filtersOpen = false;

  @override
  Widget build(BuildContext context) {
    const Color bleuProfond = Color(0xFF1A237E);
    const Color bleuCyan = Color(0xFF00ACC1);
    const Color grisClair = Color(0xFFF5F7FA);
    const Color blanc = Colors.white;
    const Color grisFonce = Color(0xFF2E3A44);
    final textTheme = Theme.of(context).textTheme;

    Widget sectionCard({required String title, required String subtitle}) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: blanc,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: bleuProfond)),
            const SizedBox(height: 8),
            Text(subtitle, style: textTheme.bodyMedium?.copyWith(color: grisFonce)),
            const SizedBox(height: 12),
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: grisClair,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE3E8EF)),
              ),
              alignment: Alignment.center,
              child: Text('Aucun contenu pour le moment', style: textTheme.bodySmall),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header full-width
            Container(
              decoration: BoxDecoration(
                color: bleuProfond,
                boxShadow: const [BoxShadow(color: Color(0x121A237E), blurRadius: 16, offset: Offset(0, 2))],
                border: const Border(bottom: BorderSide(color: bleuCyan, width: 4)),
              ),
              padding: const EdgeInsets.only(top: 76, bottom: 56),
              child: Stack(
                children: [
                  // Top-right auth area (white, no bubble)
                  Positioned(
                    right: 16,
                    top: -15,
                    child: ValueListenableBuilder<UserSession?>(
                      valueListenable: SessionStore.I.session,
                      builder: (context, session, _) {
                        if (session == null) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/login'),
                                style: TextButton.styleFrom(
                                  foregroundColor: blanc,
                                  textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                                ),
                                child: const Text('Se connecter'),
                              ),
                              const SizedBox(width: 6),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/register'),
                                style: TextButton.styleFrom(
                                  foregroundColor: blanc,
                                  textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                                ),
                                child: const Text("S'inscrire"),
                              ),
                            ],
                          );
                        }
                        final display = (session.username?.isNotEmpty ?? false)
                          ? session.username!
                          : ((session.email ?? '').split('@').first);
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              display,
                              style: GoogleFonts.montserrat(
                                fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16,
                                fontWeight: FontWeight.w600,
                                color: blanc,
                              ),
                            ),
                            IconButton(
                              onPressed: () => SessionStore.I.clear(),
                              icon: const Icon(Icons.logout, size: 18, color: blanc),
                              tooltip: 'Se déconnecter',
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  // Centered title + search + filters toggle
                  Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Tikiya',
                                style: GoogleFonts.montserrat(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: blanc,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              TextSpan(
                                text: '!',
                                style: GoogleFonts.montserrat(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF00ACC1),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Explorez, réservez et vivez les meilleurs événements',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF00ACC1),
                            letterSpacing: 0.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        // Search bar (shorter width)
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                          constraints: const BoxConstraints(maxWidth: 360),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          height: 52,
                          decoration: BoxDecoration(
                            color: blanc,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: bleuCyan, width: 1.5),
                            boxShadow: const [BoxShadow(color: Color(0x141A237E), blurRadius: 12, offset: Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: TextField(
                                  style: TextStyle(fontSize: 16, height: 1.0),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                    border: InputBorder.none,
                                    hintText: 'Rechercher un événement...',
                                  ),
                                ),
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(color: grisFonce, shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: const Icon(Icons.search, size: 22, color: bleuCyan),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => setState(() => _filtersOpen = !_filtersOpen),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(color: grisFonce, shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.tune, size: 20, color: bleuCyan),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Filters only when toggled
                        if (_filtersOpen)
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDFDFE),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE3E8EF)),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Wrap(spacing: 16, runSpacing: 8, children: [
                                  FilterChipPlaceholder(label: 'Musique'),
                                  FilterChipPlaceholder(label: 'Culture'),
                                  FilterChipPlaceholder(label: 'Divertissement'),
                                ]),
                                SizedBox(height: 12),
                                Row(children: [
                                  Expanded(child: LabeledInput(label: 'Ville', hint: 'Ex: Paris')),
                                  SizedBox(width: 12),
                                  Expanded(child: LabeledInput(label: 'Date', hint: 'Choisir une date')),
                                ]),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Main content centered with max width
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      final children = <Widget>[
                        sectionCard(title: 'Musique', subtitle: 'Aucun résultat'),
                        sectionCard(title: 'Culture', subtitle: 'Aucun résultat'),
                        sectionCard(title: 'Divertissement', subtitle: 'Aucun résultat'),
                        sectionCard(title: 'Populaire', subtitle: 'Aucun résultat'),
                      ];
                      if (isWide) {
                        return GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: children,
                        );
                      }
                      return Column(
                        children: [
                          for (final c in children) ...[c, const SizedBox(height: 16)],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
