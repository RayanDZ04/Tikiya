import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ui/tikiya_colors.dart';
import '../l10n/app_localizations.dart';
import 'language_menu.dart';

enum TopNavSection {
  discover,
  events,
  participants,
  organizers,
}

class TopNavigationBar extends StatelessWidget {
  final TopNavSection? active;
  final Widget? trailing;
  final VoidCallback? onLogin;
  final VoidCallback? onRegister;
  final bool showParticipants;

  const TopNavigationBar({
    super.key,
    this.active,
    this.trailing,
    this.onLogin,
    this.onRegister,
    this.showParticipants = true,
  });

  void _go(BuildContext context, String route) {
    final current = ModalRoute.of(context)?.settings.name;
    if (current == route) return;
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final brandStyle = GoogleFonts.montserrat(
      textStyle: textTheme.titleLarge,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.4,
    );

    const showNavLinks = true;

    return Row(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: l10n.t('app_title'),
                style: brandStyle.copyWith(color: Colors.white),
              ),
              TextSpan(
                text: '!',
                style: brandStyle.copyWith(color: TikiyaColors.bleuCyan),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: showNavLinks
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    // Always keep page names visible; on small screens, allow horizontal scrolling.
                    final spacing = constraints.maxWidth >= 520 ? 14.0 : 8.0;

                    return Align(
                      alignment: Alignment.center,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _NavLink(
                                label: l10n.t('nav_discover'),
                                isActive: active == TopNavSection.discover,
                                onTap: () => _go(context, '/'),
                              ),
                              SizedBox(width: spacing),
                              _NavLink(
                                label: l10n.t('nav_events'),
                                isActive: active == TopNavSection.events,
                                onTap: () => _go(context, '/events'),
                              ),
                              SizedBox(width: spacing),
                              if (showParticipants) ...[
                                _NavLink(
                                  label: l10n.t('nav_participants'),
                                  isActive: active == TopNavSection.participants,
                                  onTap: () => _go(context, '/participant'),
                                ),
                                SizedBox(width: spacing),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
              : const SizedBox.shrink(),
        ),
        if (trailing != null) ...[
          trailing!,
        ] else ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final showOrganizerCta = screenWidth >= 520;
              final routeName = ModalRoute.of(context)?.settings.name;
              final isOrganizerSection = routeName == '/orga' || routeName == '/orga-needs';
              final organizerCtaLabel = isOrganizerSection
                  ? l10n.t('cta_im_participant')
                  : l10n.t('cta_im_organizer');
                final organizerCtaRoute = isOrganizerSection ? '/participant' : '/orga';

              return Wrap(
                spacing: 8,
                children: [
                  const LanguageMenu(),
                  if (showOrganizerCta)
                    _PillButton(
                      label: organizerCtaLabel,
                      onPressed: () => _go(context, organizerCtaRoute),
                      variant: _PillVariant.ghost,
                      trailingIcon: Icons.north_east_rounded,
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  const _NavLink({
    required this.label,
    this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.white.withValues(alpha: 0.86);
    final activeColor = TikiyaColors.bleuCyan;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? activeColor : baseColor,
          ),
        ),
      ),
    );
  }
}

enum _PillVariant { ghost, primary }

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final _PillVariant variant;
  final IconData? trailingIcon;

  const _PillButton({
    required this.label,
    required this.onPressed,
    required this.variant,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(10));

    if (variant == _PillVariant.primary) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: TikiyaColors.bleuCyanPremium,
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: const RoundedRectangleBorder(borderRadius: borderRadius),
          ),
          child: _PillLabel(label: label, trailingIcon: trailingIcon),
        ),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: const RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      child: _PillLabel(label: label, trailingIcon: trailingIcon),
    );
  }
}

class _PillLabel extends StatelessWidget {
  final String label;
  final IconData? trailingIcon;

  const _PillLabel({required this.label, this.trailingIcon});

  @override
  Widget build(BuildContext context) {
    if (trailingIcon == null) {
      return Text(label, style: const TextStyle(fontWeight: FontWeight.w700));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Icon(trailingIcon, size: 16),
      ],
    );
  }
}
