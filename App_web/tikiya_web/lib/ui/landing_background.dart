import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'pattern_band.dart';
import 'tikiya_colors.dart';

class LandingBackground extends StatefulWidget {
  final Color? baseColor;
  final Color? darkColor;
  final Color? glowColor;
  final Color? accentGlowColor;
  final Color? streakColor;
  final bool showPatternBands;
  final Color? bandBaseColor;
  final Color? bandAccentColor;

  const LandingBackground({
    super.key,
    this.baseColor,
    this.darkColor,
    this.glowColor,
    this.accentGlowColor,
    this.streakColor,
    this.showPatternBands = true,
    this.bandBaseColor,
    this.bandAccentColor,
  });

  @override
  State<LandingBackground> createState() => _LandingBackgroundState();
}

class _LandingBackgroundState extends State<LandingBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 15),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final wave = math.sin(t * 2 * math.pi);
          final wave2 = math.cos(t * 2 * math.pi);
          final wave3 = math.sin((t * 2 * math.pi) + (math.pi / 3));

          final gradientCenter = Alignment(
            0.35 + 0.06 * wave,
            -0.55 + 0.05 * wave2,
          );

          final streakAlpha = 0.30 + 0.07 * ((wave + 1) / 2);
          final streak2Alpha = 0.10 + 0.06 * ((wave2 + 1) / 2);

          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: gradientCenter,
                      radius: 1.05,
                      colors: [
                        (widget.baseColor ?? TikiyaColors.bleuProfond)
                            .withValues(alpha: 0.95),
                        widget.darkColor ?? const Color(0xFF070A14),
                      ],
                    ),
                  ),
                ),
              ),

              // Soft floating glows
              Positioned(
                left: -140 + 28 * wave2,
                top: 120 + 22 * wave,
                child: _GlowBlob(
                  size: 280,
                  color: widget.glowColor ?? TikiyaColors.bleuCyan,
                  opacity: 0.14,
                ),
              ),
              Positioned(
                right: -120 + 18 * wave,
                top: 40 + 18 * wave3,
                child: _GlowBlob(
                  size: 220,
                  color: widget.accentGlowColor ?? const Color(0xFF3B82F6),
                  opacity: 0.12,
                ),
              ),
              Positioned(
                right: -200 + 22 * wave2,
                bottom: -140 + 18 * wave,
                child: const _GlowBlob(
                  size: 360,
                  color: Colors.white,
                  opacity: 0.06,
                ),
              ),

              // Moving streaks (subtle)
              Positioned(
                right: -180 + 18 * wave,
                top: 260 + 14 * wave2,
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
                          (widget.streakColor ?? TikiyaColors.bleuCyan)
                              .withValues(alpha: 0.0),
                          (widget.streakColor ?? TikiyaColors.bleuCyan)
                              .withValues(alpha: streakAlpha),
                          (widget.streakColor ?? TikiyaColors.bleuCyan)
                              .withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -220 + 14 * wave2,
                bottom: -40 + 10 * wave,
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
                          Colors.white.withValues(alpha: streak2Alpha),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (widget.showPatternBands) ...[
                // Animated moucharabieh-like side bands
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: _AnimatedPatternBand(
                    animation: _controller,
                    width: 120,
                    baseOpacity: 0.10,
                    phase: 0.0,
                    bandBaseColor: widget.bandBaseColor,
                    bandAccentColor: widget.bandAccentColor,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: _AnimatedPatternBand(
                    animation: _controller,
                    width: 120,
                    baseOpacity: 0.10,
                    phase: 0.55,
                    bandBaseColor: widget.bandBaseColor,
                    bandAccentColor: widget.bandAccentColor,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowBlob({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedPatternBand extends StatelessWidget {
  final Animation<double> animation;
  final double width;
  final double baseOpacity;
  final double phase;
  final Color? bandBaseColor;
  final Color? bandAccentColor;

  const _AnimatedPatternBand({
    required this.animation,
    required this.width,
    required this.baseOpacity,
    required this.phase,
    this.bandBaseColor,
    this.bandAccentColor,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          final w1 = math.sin((t * 2 * math.pi) + (phase * 2 * math.pi));
          final w2 = math.cos((t * 2 * math.pi) + (phase * 2 * math.pi));

          final drift = Offset(0, 10 * w1);
          final opacity = (baseOpacity * (0.82 + 0.18 * ((w2 + 1) / 2))).clamp(0.0, 1.0);

          // Shimmer that slowly moves through the band.
          final shimmerX = -1.2 + (2.4 * t);
          final shimmer = LinearGradient(
            begin: Alignment(shimmerX, -1.0),
            end: Alignment(shimmerX + 0.8, 1.0),
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.10),
              Colors.transparent,
            ],
            stops: const [0.35, 0.50, 0.65],
          );

          return Transform.translate(
            offset: drift,
            child: ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (rect) => shimmer.createShader(rect),
              child: PatternBand(
                width: width,
                opacity: opacity,
                baseColor: bandBaseColor ?? TikiyaColors.bleuProfond,
                accentColor: bandAccentColor ?? TikiyaColors.bleuCyan,
              ),
            ),
          );
        },
      ),
    );
  }
}
