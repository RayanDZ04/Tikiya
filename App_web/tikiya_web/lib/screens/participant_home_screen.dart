import 'package:flutter/material.dart';

import '../ui/landing_background.dart';
import '../ui/tikiya_colors.dart';
import '../widgets/top_navigation_bar.dart';

class ParticipantHomeScreen extends StatelessWidget {
  const ParticipantHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF070A14),
      body: Stack(
        children: [
          const Positioned.fill(child: LandingBackground()),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TopNavigationBar(
                        active: TopNavSection.participants,
                        onLogin: () => Navigator.of(context).pushNamed('/login'),
                        onRegister: () => Navigator.of(context).pushNamed('/register'),
                      ),
                      const SizedBox(height: 44),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 920;
                            return SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _ParticipantHero(textTheme: textTheme, compact: !wide),
                                  const SizedBox(height: 28),
                                  _FeatureGrid(wide: wide),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantHero extends StatelessWidget {
  final TextTheme textTheme;
  final bool compact;

  const _ParticipantHero({required this.textTheme, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final titleStyle = (compact ? textTheme.headlineMedium : textTheme.displaySmall)?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w900,
      height: 1.05,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Simplifiez vos sorties\navec Tikiya', style: titleStyle),
        const SizedBox(height: 14),
        Text(
          'Accédez à vos billets, QR code et événements en un seul endroit.',
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _PillAction(
              label: 'Mes événements',
              variant: _PillVariant.primary,
              onPressed: () => Navigator.of(context).pushNamed('/events'),
            ),
            _PillAction(
              label: 'Retour Découvrir',
              variant: _PillVariant.ghost,
              onPressed: () => Navigator.of(context).pushNamed('/'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final bool wide;

  const _FeatureGrid({required this.wide});

  @override
  Widget build(BuildContext context) {
    final maxWidth = wide ? 980.0 : 720.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: const [
            _FeatureCard(
              title: 'Billet QR code\nsécurisé',
              subtitle: 'Votre billet généré\ninstantanément.',
              asset: 'assets/ticket_logo.webp',
            ),
            _FeatureCard(
              title: 'Billets\nMarketplace',
              subtitle: 'Revendez vos billets\nfacilement.',
              asset: 'assets/ordi.png',
            ),
            _FeatureCard(
              title: 'Paiement flexible',
              subtitle: 'Carte bancaire ou en\nespèces au bureau de tabac.',
              asset: 'assets/moucharabieh.png',
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String asset;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 310),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 22, offset: Offset(0, 14)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(asset, fit: BoxFit.contain, filterQuality: FilterQuality.high),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PillVariant { ghost, primary }

class _PillAction extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final _PillVariant variant;

  const _PillAction({
    required this.label,
    required this.onPressed,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == _PillVariant.primary) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: TikiyaColors.bleuCyanPremium,
          boxShadow: const [
            BoxShadow(color: Color(0x3300B8D4), blurRadius: 18, offset: Offset(0, 10)),
          ],
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: const StadiumBorder(),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: const StadiumBorder(),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
