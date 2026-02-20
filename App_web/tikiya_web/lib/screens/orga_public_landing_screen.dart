import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ui/tikiya_colors.dart';
import '../ui/landing_background.dart';
import '../l10n/app_localizations.dart';
import '../services/seo_meta.dart';
import '../widgets/language_menu.dart';

class OrgaPublicLandingScreen extends StatefulWidget {
  final VoidCallback onNeeds;

  const OrgaPublicLandingScreen({
    super.key,
    required this.onNeeds,
  });

  @override
  State<OrgaPublicLandingScreen> createState() => _OrgaPublicLandingScreenState();
}

class _OrgaPublicLandingScreenState extends State<OrgaPublicLandingScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    SeoMeta.set(
      title: l10n.t('seo_orga_title'),
      description: l10n.t('seo_orga_description'),
    );
    return Scaffold(
      backgroundColor: TikiyaColors.grisFonce,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;

          return Stack(
            children: [
              Positioned.fill(
                child: LandingBackground(
                  baseColor: TikiyaColors.grisFonce,
                  darkColor: const Color(0xFF111111),
                  showPatternBands: true,
                  bandBaseColor: const Color(0xFF2B2B2B),
                  bandAccentColor: const Color(0xFF9E9E9E),
                ),
              ),
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
                              if (isRtl) ...[
                                _TopLoginButton(
                                  onPressed: () => Navigator.of(context).pushNamed('/participant'),
                                  label: l10n.t('cta_im_participant'),
                                  trailingIcon: Icons.north_east_rounded,
                                ),
                                const SizedBox(width: 10),
                                _TopLoginButton(
                                  onPressed: () => Navigator.of(context).pushNamed('/contact'),
                                  label: l10n.t('cta_contact'),
                                  trailingIcon: Icons.mail_outline_rounded,
                                ),
                                const SizedBox(width: 10),
                                const LanguageMenu(),
                                const Spacer(),
                                const _BrandTitle(),
                              ] else ...[
                                const _BrandTitle(),
                                const Spacer(),
                                const LanguageMenu(),
                                const SizedBox(width: 10),
                                _TopLoginButton(
                                  onPressed: () => Navigator.of(context).pushNamed('/contact'),
                                  label: l10n.t('cta_contact'),
                                  trailingIcon: Icons.mail_outline_rounded,
                                ),
                                const SizedBox(width: 10),
                                _TopLoginButton(
                                  onPressed: () => Navigator.of(context).pushNamed('/participant'),
                                  label: l10n.t('cta_im_participant'),
                                  trailingIcon: Icons.north_east_rounded,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 28),
                          Expanded(child: _HeroBody(isWide: isWide, l10n: l10n)),
                          const SizedBox(height: 18),
                          // Only keep "Échanger sur vos besoins" for the static-only launch.
                          Center(
                            child: Transform.translate(
                              offset: const Offset(0, -20),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                alignment: isRtl ? WrapAlignment.end : WrapAlignment.center,
                                children: [
                                  _CtaButton(
                                    label: l10n.t('orga_cta_secondary'),
                                    onPressed: widget.onNeeds,
                                    variant: _CtaVariant.ghost,
                                  ),
                                ],
                              ),
                            ),
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
  final AppLocalizations l10n;

  const _HeroBody({required this.isWide, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return LayoutBuilder(
      builder: (context, constraints) {
        final desiredWidth = isWide
            ? (constraints.maxWidth * 0.62).clamp(560.0, 820.0)
            : (constraints.maxWidth * 0.90).clamp(320.0, 520.0);

        final visualWidth = desiredWidth.clamp(0.0, constraints.maxWidth);
        final bottomPadding = isWide ? 6.0 : 220.0;
        final visualScale = isWide ? 1.03 : 1.0;
        final visualYOffset = isWide ? 29.0 : 0.0;

        if (!isWide) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _LeftColumn(
                  bottomPadding: 0,
                  l10n: l10n,
                  isRtl: isRtl,
                  isWide: false,
                  scrollable: false,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 360,
                  child: IgnorePointer(
                    child: _RightVisual(scale: 1.42, yOffset: 0),
                  ),
                ),
              ],
            ),
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: isRtl ? null : 150,
              left: isRtl ? (isAr ? 200 : 150) : null,
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
            Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              right: isAr ? 150 : 0,
              child: Align(
                alignment: isRtl ? Alignment.topRight : Alignment.topLeft,
                child: _LeftColumn(
                  bottomPadding: bottomPadding,
                  l10n: l10n,
                  isRtl: isRtl,
                  isWide: isWide,
                ),
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
    final l10n = context.l10n;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final locale = Localizations.localeOf(context);
    final isAr = locale.languageCode == 'ar';
    final baseStyle = (isAr ? GoogleFonts.cairo : GoogleFonts.montserrat)(
      textStyle: textTheme.titleLarge,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: isAr ? 0.0 : 0.4,
      height: isAr ? 1.15 : null,
      color: Colors.white,
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: l10n.t('app_title'), style: baseStyle),
          TextSpan(
            text: '!',
            style: baseStyle.copyWith(color: TikiyaColors.bleuCyan),
          ),
          TextSpan(
            text: ' Pro',
            style: baseStyle.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
    );
  }
}


class _TopLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData? trailingIcon;

  const _TopLoginButton({required this.onPressed, required this.label, this.trailingIcon});

  @override
  Widget build(BuildContext context) {
    final labelWidget = trailingIcon == null
        ? Text(label, style: const TextStyle(fontWeight: FontWeight.w700))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Icon(trailingIcon, size: 18),
            ],
          );

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: labelWidget,
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
                'assets/ordi.webp',
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
  final AppLocalizations l10n;
  final bool isRtl;
  final bool isWide;
  final bool scrollable;

  const _LeftColumn({
    required this.bottomPadding,
    required this.l10n,
    required this.isRtl,
    this.isWide = false,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final extraOffset = (isAr && isWide) ? -200.0 : 0.0;
    final arOffset = (isAr && isWide) ? -150.0 + extraOffset : 0.0;

    final body = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Column(
        crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Transform.translate(
            offset: Offset(arOffset, 0),
            child: Column(
              crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('orga_public_title'),
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  style: textTheme.displaySmall?.copyWith(
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.30),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.t('orga_public_subtitle'),
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  style: textTheme.bodyLarge?.copyWith(
                    height: 1.55,
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Transform.translate(
            offset: Offset(arOffset, 0),
            child: Column(
              crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _FeatureItem(
                  icon: Icons.dashboard_outlined,
                  title: l10n.t('orga_feature1_title'),
                  subtitle: l10n.t('orga_feature1_sub'),
                  isRtl: isRtl,
                ),
                const SizedBox(height: 16),
                _FeatureItem(
                  icon: Icons.insights_outlined,
                  title: l10n.t('orga_feature2_title'),
                  subtitle: l10n.t('orga_feature2_sub'),
                  isRtl: isRtl,
                ),
                const SizedBox(height: 16),
                _FeatureItem(
                  icon: Icons.add_box_outlined,
                  title: l10n.t('orga_feature3_title'),
                  subtitle: l10n.t('orga_feature3_sub'),
                  isRtl: isRtl,
                ),
                const SizedBox(height: 16),
                _FeatureItem(
                  icon: Icons.tune_outlined,
                  title: l10n.t('orga_feature4_title'),
                  subtitle: l10n.t('orga_feature4_sub'),
                  isRtl: isRtl,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Align(
      alignment: isRtl ? Alignment.topRight : Alignment.topLeft,
      child: scrollable
          ? SingleChildScrollView(
              clipBehavior: Clip.none,
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: body,
            )
          : body,
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isRtl;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isRtl = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final content = Expanded(
      child: Column(
        crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            style: textTheme.bodyMedium?.copyWith(
              height: 1.35,
              color: Colors.white.withValues(alpha: 0.65),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    final iconBadge = Container(
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
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: isRtl
          ? [
              content,
              const SizedBox(width: 12),
              iconBadge,
            ]
          : [
              iconBadge,
              const SizedBox(width: 12),
              content,
            ],
    );
  }
}

class _CtaActions extends StatelessWidget {
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final AppLocalizations l10n;

  const _CtaActions({required this.onPrimary, required this.onSecondary, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final primary = _CtaButton(
      label: l10n.t('orga_cta_primary'),
      onPressed: onPrimary,
      variant: _CtaVariant.primary,
    );
    final secondary = _CtaButton(
      label: l10n.t('orga_cta_secondary'),
      onPressed: onSecondary,
      variant: _CtaVariant.ghost,
    );

    return Center(
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: isRtl ? WrapAlignment.end : WrapAlignment.center,
          children: [
            if (isRtl) ...[secondary, primary] else ...[primary, secondary],
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
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
