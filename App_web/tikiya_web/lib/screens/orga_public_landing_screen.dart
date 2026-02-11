import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ui/tikiya_colors.dart';
import '../ui/landing_background.dart';

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
                          Row(
                            children: [
                              const _BrandTitle(),
                              const Spacer(),
                              _TopLoginButton(onPressed: widget.onCta),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Expanded(
                            child: _HeroBody(isWide: isWide),
                          ),
                          const SizedBox(height: 18),
                          _CtaActions(
                            onPrimary: widget.onCta,
                            onSecondary: widget.onCta,
                          ),
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
        final visualScale = isWide ? 1.08 : 1.0;
        final visualYOffset = isWide ? 29.0 : 0.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: 150,
              bottom: -100,
              child: IgnorePointer(
                child: SizedBox(
                  width: visualWidth,
                  child: _RightVisual(
                    scale: visualScale,
                    yOffset: visualYOffset,
                  ),
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

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final baseStyle = GoogleFonts.montserrat(
      textStyle: textTheme.titleLarge,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.4,
      color: Colors.white,
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Tikiya', style: baseStyle),
          TextSpan(
            text: '!',
            style: baseStyle.copyWith(color: TikiyaColors.bleuCyan),
          ),
        ],
      ),
    );
  }
}

class _TopLoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _TopLoginButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _RightVisual extends StatelessWidget {
  final double scale;
  final double yOffset;

  const _RightVisual({this.scale = 1.0, this.yOffset = 0.0});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight,
          ),
          child: Transform.translate(
            offset: Offset(0, yOffset),
            child: Transform.scale(
              scale: scale,
              child: Image.asset(
                'assets/ordi.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                filterQuality: FilterQuality.high,
              ),
            ),
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

class _CtaActions extends StatelessWidget {
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _CtaActions({required this.onPrimary, required this.onSecondary});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _CtaButton(
              label: 'Commencer maintenant',
              onPressed: onPrimary,
              variant: _CtaVariant.primary,
            ),
            _CtaButton(
              label: 'Échanger sur vos besoins',
              onPressed: onSecondary,
              variant: _CtaVariant.ghost,
            ),
          ],
        ),
      ),
    );
  }
}

enum _CtaVariant { primary, ghost }

class _CtaButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final _CtaVariant variant;

  const _CtaButton({
    required this.label,
    required this.onPressed,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == _CtaVariant.primary) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [Color(0xFF1F5BFF), Color(0xFF00ACC1)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00ACC1).withValues(alpha: 0.30),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text(
            'Commencer maintenant',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
    );
  }
}
