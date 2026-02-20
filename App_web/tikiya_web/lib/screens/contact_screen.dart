import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../services/seo_meta.dart';
import '../ui/landing_background.dart';
import '../ui/tikiya_colors.dart';
import '../widgets/language_menu.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    SeoMeta.set(
      title: l10n.t('seo_contact_title'),
      description: l10n.t('seo_contact_description'),
    );

    return Scaffold(
      backgroundColor: TikiyaColors.grisFonce,
      body: Stack(
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
                constraints: const BoxConstraints(maxWidth: 980),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 18, 26, 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (isRtl) ...[
                            _TopActionButton(
                              label: l10n.t('cta_back'),
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icons.west_rounded,
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
                            _TopActionButton(
                              label: l10n.t('cta_back'),
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icons.west_rounded,
                            ),
                          ],
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 700),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.t('contact_title'),
                              textAlign: isRtl ? TextAlign.right : TextAlign.left,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.t('contact_subtitle'),
                              textAlign: isRtl ? TextAlign.right : TextAlign.left,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: const Color(0xFF0EA5B7),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0EA5B7).withValues(alpha: 0.36),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.mark_email_read_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    SelectableText(
                                      'contact@tikiya.dz',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
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
          TextSpan(text: '!', style: baseStyle.copyWith(color: TikiyaColors.bleuCyan)),
          TextSpan(
            text: ' Pro',
            style: baseStyle.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
    );
  }
}

class _TopActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  const _TopActionButton({required this.label, required this.onPressed, required this.icon});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
