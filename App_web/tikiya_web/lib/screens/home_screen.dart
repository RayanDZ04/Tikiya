import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../ui/tikiya_colors.dart';
import '../ui/landing_background.dart';
import '../widgets/top_navigation_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF070A14),
      body: Stack(
        children: [
          const Positioned.fill(child: LandingBackground()),
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
                                    final left = _HeroCopy(textTheme: textTheme, compactTitle: true);
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 30),
                                      child: Stack(
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
                                      ),
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


class _TopNav extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const _TopNav({
    required this.onLogin,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return TopNavigationBar(
      active: TopNavSection.discover,
      onLogin: onLogin,
      onRegister: onRegister,
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final TextTheme textTheme;
  final bool compactTitle;

  const _HeroCopy({
    required this.textTheme,
    this.compactTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = compactTitle
        ? 'Le moyen le plus simple\nd’entrer aux meilleurs\névénements'
        : 'Le moyen le plus simple\nd’entrer aux meilleurs événements';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Billets sécurisés, QR code et accès rapide.',
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
              label: 'Télécharger avec Google Play',
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

class _HeroBottomBlock extends StatelessWidget {
  final bool alignLeft;

  const _HeroBottomBlock({this.alignLeft = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: _PrimaryButton(
            label: 'Voir tous les événements',
            onPressed: () => Navigator.of(context).pushNamed('/events'),
            icon: Icons.arrow_forward_rounded,
          ),
        ),
      ],
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
