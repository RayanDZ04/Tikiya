import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ui/tikiya_colors.dart';

enum TopNavSection {
  discover,
  events,
  organizers,
  help,
}

class TopNavigationBar extends StatelessWidget {
  final TopNavSection? active;
  final Widget? trailing;
  final VoidCallback? onLogin;
  final VoidCallback? onRegister;

  const TopNavigationBar({
    super.key,
    this.active,
    this.trailing,
    this.onLogin,
    this.onRegister,
  });

  void _go(BuildContext context, String route) {
    final current = ModalRoute.of(context)?.settings.name;
    if (current == route) return;
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final brandStyle = GoogleFonts.montserrat(
      textStyle: textTheme.titleLarge,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.4,
    );

    return Row(
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
        const SizedBox(width: 18),
        Expanded(
          child: LayoutBuilder(
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
                          label: 'Découvrir',
                          isActive: active == TopNavSection.discover,
                          onTap: () => _go(context, '/'),
                        ),
                        SizedBox(width: spacing),
                        _NavLink(
                          label: 'Événements',
                          isActive: active == TopNavSection.events,
                          onTap: () => _go(context, '/events'),
                        ),
                        SizedBox(width: spacing),
                        _NavLink(
                          label: 'Organisateurs',
                          isActive: active == TopNavSection.organizers,
                          onTap: () => _go(context, '/orga'),
                        ),
                        SizedBox(width: spacing),
                        _NavLink(
                          label: 'Aide',
                          isActive: active == TopNavSection.help,
                          onTap: () => _go(context, '/help'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (trailing != null) ...[
          trailing!,
        ] else ...[
          Wrap(
            spacing: 8,
            children: [
              _PillButton(
                label: 'Se connecter',
                onPressed: onLogin ?? () => _go(context, '/login'),
                variant: _PillVariant.ghost,
              ),
              _PillButton(
                label: 'Créer un compte',
                onPressed: onRegister ?? () => _go(context, '/register'),
                variant: _PillVariant.primary,
              ),
            ],
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

  const _PillButton({
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
          gradient: const LinearGradient(
            colors: [Color(0xFF1F5BFF), Color(0xFF00ACC1)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: const StadiumBorder(),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
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
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
