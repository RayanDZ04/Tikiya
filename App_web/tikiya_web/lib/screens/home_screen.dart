import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ui/tikiya_colors.dart';
import '../ui/pattern_band.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF070A14),
      body: Stack(
        children: [
          const Positioned.fill(child: _LandingBackground()),
          Positioned.fill(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TopNav(
                                onLogin: () => Navigator.of(context).pushNamed('/login'),
                                onRegister: () => Navigator.of(context).pushNamed('/register'),
                              ),
                              const SizedBox(height: 44),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final wide = constraints.maxWidth >= 920;
                                  if (!wide) {
                                    final left = _HeroCopy(textTheme: textTheme);
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: IgnorePointer(
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(maxWidth: 420),
                                              child: Transform.translate(
                                                offset: const Offset(0, -40),
                                                child: const _PhoneMock(),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            left,
                                            const SizedBox(height: 25),
                                            const _HeroBottomBlock(),
                                          ],
                                        ),
                                      ],
                                    );
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: const [
                                      _HeroWide(),
                                      SizedBox(height: 10),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroWide extends StatefulWidget {
  const _HeroWide();

  @override
  State<_HeroWide> createState() => _HeroWideState();
}

class _HeroWideState extends State<_HeroWide> {
  double _leftHeight = 0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: _MeasureSize(
                onChange: (size) {
                  if (!mounted) return;
                  if ((size.height - _leftHeight).abs() <= 0.5) return;
                  setState(() => _leftHeight = size.height);
                },
                child: _HeroCopy(textTheme: textTheme),
              ),
            ),
            const SizedBox(width: 28),
            const Expanded(flex: 5, child: _PhoneMock()),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          top: _leftHeight + 25,
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 940),
              child: const _HeroBottomBlock(alignLeft: true),
            ),
          ),
        ),
      ],
    );
  }
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChange;

  const _MeasureSize({
    required this.onChange,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMeasureSize(onChange);
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderMeasureSize).onChange = onChange;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  ValueChanged<Size> onChange;
  Size? _oldSize;

  _RenderMeasureSize(this.onChange);

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size ?? Size.zero;
    if (_oldSize == newSize) return;
    _oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(newSize));
  }
}

class _LandingBackground extends StatelessWidget {
  const _LandingBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.35, -0.55),
                radius: 1.05,
                colors: [
                  TikiyaColors.bleuProfond.withValues(alpha: 0.95),
                  const Color(0xFF070A14),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: -180,
          top: 260,
          child: Transform.rotate(
            angle: -0.35,
            child: Container(
              width: 820,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    TikiyaColors.bleuCyan.withValues(alpha: 0.0),
                    TikiyaColors.bleuCyan.withValues(alpha: 0.35),
                    TikiyaColors.bleuCyan.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -220,
          bottom: -40,
          child: Transform.rotate(
            angle: -0.35,
            child: Container(
              width: 920,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Positioned(left: 0, top: 0, bottom: 0, child: PatternBand(width: 120, opacity: 0.10)),
        const Positioned(right: 0, top: 0, bottom: 0, child: PatternBand(width: 120, opacity: 0.10)),
      ],
    );
  }
}

class _TopNav extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const _TopNav({
    required this.onLogin,
    required this.onRegister,
  });

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
              final showLinks = constraints.maxWidth >= 520;
              if (!showLinks) return const SizedBox.shrink();

              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 8,
                children: const [
                  _NavLink(label: 'Découvrir'),
                  _NavLink(label: 'Événements'),
                  _NavLink(label: 'Organisateurs'),
                  _NavLink(label: 'Aide'),
                ],
              );
            },
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            _PillButton(
              label: 'Se connecter',
              onPressed: onLogin,
              variant: _PillVariant.ghost,
            ),
            _PillButton(
              label: 'Créer un compte',
              onPressed: onRegister,
              variant: _PillVariant.filled,
            ),
          ],
        ),
      ],
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  const _NavLink({required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final TextTheme textTheme;
  const _HeroCopy({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore, réserve et vis\nles meilleurs événements',
          style: textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Billets, guestlists et recommandations pour\nne rien rater autour de toi.',
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _GooglePlayButton(
              label: 'Installer avec Google Play',
              onPressed: () {},
            ),
            _AppleStoreButton(
              label: "Télécharger sur l’App Store",
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _PhoneMock extends StatelessWidget {
  const _PhoneMock();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Aperçu de l’application mobile',
      image: true,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.9,
                  heightFactor: 0.9,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.2, -0.2),
                          radius: 0.9,
                          colors: [
                            TikiyaColors.bleuCyan.withValues(alpha: 0.35),
                            const Color(0xFF3B82F6).withValues(alpha: 0.22),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Image.asset(
            'assets/Iphone.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  final bool alignLeft;

  const _SearchPanel({this.alignLeft = false});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final panel = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 940),
      child: _GlassCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          children: [
              Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      child: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.78), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        style: textTheme.titleSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un événement…',
                          hintStyle: textTheme.titleSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.40),
                            fontWeight: FontWeight.w600,
                          ),
                          isDense: true,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: alignLeft ? WrapAlignment.start : WrapAlignment.center,
                children: [
                  const _FilterPill(icon: Icons.place_rounded, label: 'Alger'),
                  const _FilterPill(icon: Icons.event_rounded, label: 'Ce week-end'),
                  _FilterPill(
                    icon: Icons.tune_rounded,
                    label: 'Filtres',
                    emphasis: true,
                    onTap: () {},
                  ),
                ],
              ),
          ],
        ),
      ),
    );

    return alignLeft
        ? Align(alignment: Alignment.centerLeft, child: panel)
        : Center(child: panel);
  }
}

class _HeroBottomBlock extends StatelessWidget {
  final bool alignLeft;

  const _HeroBottomBlock({this.alignLeft = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SearchPanel(alignLeft: alignLeft),
        const SizedBox(height: 18),
        Center(
          child: _PrimaryButton(
            label: 'Voir tous les événements',
            onPressed: () {},
            icon: Icons.arrow_forward_rounded,
          ),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool emphasis;
  final VoidCallback? onTap;

  const _FilterPill({
    required this.icon,
    required this.label,
    this.emphasis = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = emphasis
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.08);
    final border = Colors.white.withValues(alpha: emphasis ? 0.28 : 0.16);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.90),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PillVariant { filled, ghost }

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final _PillVariant variant;

  const _PillButton({
    required this.label,
    required this.onPressed,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    final bool filled = variant == _PillVariant.filled;

    final bg = filled
        ? TikiyaColors.bleuCyan.withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.14);
    final fg = Colors.white;
    final border = filled ? Colors.transparent : Colors.white.withValues(alpha: 0.35);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.09),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            TikiyaColors.bleuCyan.withValues(alpha: 0.95),
            const Color(0xFF3B82F6).withValues(alpha: 0.90),
          ],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x44000000), blurRadius: 18, offset: Offset(0, 10)),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _GooglePlayButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _GooglePlayButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.1,
        );

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: Colors.white,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: textStyle,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Google Play',
            image: true,
            child: Image.asset(
              'assets/playstore.webp',
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }
}

class _AppleStoreButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _AppleStoreButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.1,
        );

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: Colors.black,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: textStyle,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'App Store',
            image: true,
            child: Image.asset(
              'assets/apple.png',
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }
}
