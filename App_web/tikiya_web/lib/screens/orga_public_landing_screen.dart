import 'package:flutter/material.dart';

import '../ui/tikiya_colors.dart';
import '../ui/landing_background.dart';
import '../widgets/top_navigation_bar.dart';

class OrgaPublicLandingScreen extends StatefulWidget {
  final VoidCallback onCta;

  const OrgaPublicLandingScreen({super.key, required this.onCta});

  @override
  State<OrgaPublicLandingScreen> createState() => _OrgaPublicLandingScreenState();
}

class _OrgaPublicLandingScreenState extends State<OrgaPublicLandingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070A14),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;

          return Stack(
            children: [
              const Positioned.fill(child: LandingBackground()),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(26, 18, 26, 24),
                      child: Column(
                        children: [
                          TopNavigationBar(
                            active: TopNavSection.organizers,
                            onLogin: widget.onCta,
                            onRegister: () => Navigator.of(context).pushNamed('/register'),
                          ),
                          const SizedBox(height: 28),
                          Expanded(
                            child: _HeroBody(isWide: isWide),
                          ),
                          const SizedBox(height: 18),
                          _CtaButton(onPressed: widget.onCta),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroBody extends StatelessWidget {
  final bool isWide;

  const _HeroBody({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desiredWidth = isWide
            ? (constraints.maxWidth * 0.62).clamp(560.0, 820.0)
            : (constraints.maxWidth * 0.90).clamp(320.0, 520.0);

        final visualWidth = desiredWidth.clamp(0.0, constraints.maxWidth);
        final bottomPadding = isWide ? 6.0 : 220.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: 150,
              bottom: -100,
              child: IgnorePointer(
                child: SizedBox(
                  width: visualWidth,
                  child: const _RightVisual(),
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.topLeft,
                child: _LeftColumn(bottomPadding: bottomPadding),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RightVisual extends StatelessWidget {
  const _RightVisual();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight,
          ),
          child: Image.asset(
            'assets/ordi.png',
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            filterQuality: FilterQuality.high,
          ),
        );
      },
    );
  }
}

class _LeftColumn extends StatelessWidget {
  final double bottomPadding;

  const _LeftColumn({required this.bottomPadding});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Boostez la vente de vos billets,\nsuivez vos événements\nen temps réel',
                style: textTheme.displaySmall?.copyWith(
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Proposez vos événements, boostez vos ventes et\naccédez aux meilleures statistiques avec\nun panel organisateur intuitif.',
                style: textTheme.bodyLarge?.copyWith(
                  height: 1.55,
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 26),
              _FeatureItem(
                icon: Icons.dashboard_outlined,
                title: 'Tableau de bord complet',
                subtitle: 'Suivez tous vos événements en\nun coup d\'œil',
              ),
              const SizedBox(height: 16),
              const _FeatureItem(
                icon: Icons.insights_outlined,
                title: 'Statistiques en temps réel',
                subtitle: 'Consultez vos ventes, billets vendus,\net tendances en direct',
              ),
              const SizedBox(height: 16),
              const _FeatureItem(
                icon: Icons.add_box_outlined,
                title: 'Création d\'événements facile',
                subtitle: 'Postez vos événements\nen quelques clics',
              ),
              const SizedBox(height: 16),
              const _FeatureItem(
                icon: Icons.tune_outlined,
                title: 'Gestion en live',
                subtitle: 'Modifiez la capacité, ouvrez les ventes,\nsuivez les entrées',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF2B6DFF), TikiyaColors.bleuCyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2B6DFF).withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CtaButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CtaButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            colors: [Color(0xFF1F5BFF), Color(0xFF00ACC1)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00ACC1).withValues(alpha: 0.30),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              child: Text(
                'Accéder au panel organisateur',
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
