import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ui/tikiya_colors.dart';
import '../ui/landing_background.dart';

class OrgaPublicLandingScreen extends StatelessWidget {
  final VoidCallback onCta;

  const OrgaPublicLandingScreen({super.key, required this.onCta});

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
                          Expanded(
                            child: isWide
                                ? Stack(
                                    children: [
                                      const Positioned.fill(
                                        child: Align(
                                          alignment: Alignment.bottomRight,
                                          child: _RightVisual(),
                                        ),
                                      ),
                                      const Positioned.fill(
                                        child: _LeftColumn(),
                                      ),
                                    ],
                                  )
                                : const Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _LeftColumn(),
                                      SizedBox(height: 18),
                                      Expanded(child: _RightVisual()),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 18),
                          _CtaButton(onPressed: onCta),
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

class _LeftColumn extends StatelessWidget {
  const _LeftColumn();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final brandStyle = GoogleFonts.montserrat(
      textStyle: textTheme.titleLarge,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.4,
    );

    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Tikiya',
                      style: brandStyle.copyWith(color: Colors.white),
                    ),
                    TextSpan(
                      text: '!',
                      style: brandStyle.copyWith(color: TikiyaColors.bleuCyan),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
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
              const _FeatureItem(
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

class _RightVisual extends StatelessWidget {
  const _RightVisual();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 980;

    return Align(
      alignment: Alignment.bottomCenter,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = isWide ? 2.2 : 1.1;
          final horizontalOffset = isWide ? 240.0 : 0.0;
          final verticalOffset = isWide ? 360.0 : 0.0;

          return Transform.translate(
            offset: Offset(horizontalOffset, verticalOffset),
            child: Transform.scale(
              scale: scale,
              alignment: isWide ? Alignment.bottomRight : Alignment.bottomCenter,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.85,
                  maxHeight: constraints.maxHeight * 0.8,
                ),
                child: Image.asset(
                  'assets/ordi.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          );
        },
      ),
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
