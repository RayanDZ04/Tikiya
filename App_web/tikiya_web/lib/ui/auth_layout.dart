import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tikiya_colors.dart';
import '../widgets/top_navigation_bar.dart';
import '../l10n/app_localizations.dart';

class AuthLayout extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showSideBands;
  final double sideBandWidth;
  final double sideBandOpacity;
  final TopNavSection? activeNav;
  final Color backgroundColor;

  const AuthLayout({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.showSideBands = true,
    this.sideBandWidth = 64,
    this.sideBandOpacity = 0.16,
    this.activeNav,
    this.backgroundColor = TikiyaColors.bleuProfond,
  });

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.backgroundColor;
    final accent = base == TikiyaColors.grisFonce
      ? TikiyaColors.bleuCyan.withValues(alpha: 0.16)
      : TikiyaColors.bleuCyan.withValues(alpha: 0.22);

    return Scaffold(
      backgroundColor: base,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = _controller.value;
                  final drift = (t - 0.5) * 2;
                  final start = Alignment(-0.9 + drift * 0.6, -0.8 + drift * 0.4);
                  final end = Alignment(0.9 - drift * 0.5, 1.0 - drift * 0.3);
                  final shimmer = 0.35 + 0.25 * (0.5 + 0.5 * sin(t * 6.283));

                  return Stack(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: start,
                            radius: 1.2,
                            colors: [accent, Colors.transparent],
                          ),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: end,
                              radius: 1.35,
                              colors: [accent.withValues(alpha: shimmer), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _FloatingDotsPainter(
                            progress: t,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(26, 18, 26, 12),
                        child: TopNavigationBar(active: widget.activeNav),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 520),
                      margin: widget.padding,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: TikiyaColors.grisClair),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(11, 28, 62, 0.10),
                            blurRadius: 24,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double effectiveBandWidth = widget.showSideBands
                              ? widget.sideBandWidth
                                  .clamp(0.0, (constraints.maxWidth / 3).floorToDouble())
                                  .toDouble()
                              : 0.0;

                          return Stack(
                            children: [
                              if (widget.showSideBands && effectiveBandWidth > 0) ...[
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: effectiveBandWidth,
                                  child: Opacity(
                                    opacity: widget.sideBandOpacity,
                                    child: Image.asset(
                                      'assets/moucharabieh.webp',
                                      fit: BoxFit.cover,
                                      alignment: Alignment.centerLeft,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: effectiveBandWidth,
                                  child: Opacity(
                                    opacity: widget.sideBandOpacity,
                                    child: Image.asset(
                                      'assets/moucharabieh.webp',
                                      fit: BoxFit.cover,
                                      alignment: Alignment.centerRight,
                                    ),
                                  ),
                                ),
                              ],
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  28 + effectiveBandWidth,
                                  32,
                                  28 + effectiveBandWidth,
                                  24,
                                ),
                                child: widget.child,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TikiyaLogo extends StatelessWidget {
  final double fontSize;
  final bool showPro;
  final TextAlign textAlign;

  const TikiyaLogo({
    super.key,
    this.fontSize = 32,
    this.showPro = false,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final isAr = locale.languageCode == 'ar';
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final baseText = l10n.t('app_title');
    final baseStyle = (isAr ? GoogleFonts.cairo : GoogleFonts.montserrat)(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: TikiyaColors.bleuProfond,
      letterSpacing: isAr ? 0.0 : 0.8,
      height: isAr ? 1.15 : 1.0,
    );
    final accentStyle = baseStyle.copyWith(color: TikiyaColors.bleuCyan);
    final proStyle = (isAr ? GoogleFonts.cairo : GoogleFonts.montserrat)(
      fontSize: fontSize - 4,
      fontWeight: FontWeight.w400,
      color: TikiyaColors.grisFonce,
      letterSpacing: isAr ? 0.0 : 0.6,
      height: isAr ? 1.15 : 1.0,
    );

    final baseSpan = TextSpan(
      children: [
        TextSpan(text: baseText, style: baseStyle),
        TextSpan(text: '!', style: accentStyle),
      ],
    );

    if (!showPro) {
      return Text.rich(
        baseSpan,
        textAlign: textAlign,
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      );
    }

    // RTL/Arabic: avoid LTR-centered overlay math (it looks off in Arabic).
    // Render a clean "Pro | Tikiya!" composition.
    if (isRtl || isAr) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Pro | ', style: proStyle),
            baseSpan,
          ],
        ),
        textAlign: textAlign,
        textDirection: TextDirection.rtl,
      );
    }

    final basePainter = TextPainter(
      text: baseSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    final proPainter = TextPainter(
      text: TextSpan(text: 'Pro', style: proStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final spacePainter = TextPainter(
      text: TextSpan(text: ' ', style: proStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final offsetX = basePainter.width / 2 + spacePainter.width + proPainter.width / 2;

    return Stack(
      alignment: Alignment.center,
      children: [
        Text.rich(baseSpan, textAlign: textAlign),
        Transform.translate(
          offset: Offset(offsetX, 0),
          child: Text('Pro', style: proStyle),
        ),
      ],
    );
  }
}

class _FloatingDotsPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _FloatingDotsPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final t = progress * 2 * 3.1415926535;

    final dots = <Offset>[
      Offset(size.width * 0.15, size.height * 0.18),
      Offset(size.width * 0.32, size.height * 0.34),
      Offset(size.width * 0.78, size.height * 0.22),
      Offset(size.width * 0.64, size.height * 0.58),
      Offset(size.width * 0.22, size.height * 0.72),
      Offset(size.width * 0.86, size.height * 0.78),
    ];

    for (var i = 0; i < dots.length; i++) {
      final base = dots[i];
      final phase = t + i * 0.9;
      final dx = 10 * sin(phase);
      final dy = 12 * cos(phase);
      final radius = 2.2 + 1.4 * (0.5 + 0.5 * sin(phase));
      canvas.drawCircle(Offset(base.dx + dx, base.dy + dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingDotsPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
