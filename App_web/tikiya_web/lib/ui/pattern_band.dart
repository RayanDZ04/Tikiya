import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tikiya_colors.dart';

class PatternBand extends StatelessWidget {
  final double width;
  final double opacity;

  const PatternBand({
    super.key,
    this.width = 120,
    this.opacity = 0.22,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: width,
        child: CustomPaint(
          painter: _PatternPainter(opacity: opacity),
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final double opacity;

  const _PatternPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    // Base background gradient-ish
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0B1C3E),
          Color(0xFF0B1C3E),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final line = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fill = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.55)
      ..style = PaintingStyle.fill;

    const double tile = 84;
    final cols = (size.width / tile).ceil() + 1;
    final rows = (size.height / tile).ceil() + 1;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final dx = c * tile;
        final dy = r * tile;
        final cx = dx + tile / 2;
        final cy = dy + tile / 2;

        // Big diamond
        final diamond = Path()
          ..moveTo(cx, dy + 10)
          ..lineTo(dx + tile - 10, cy)
          ..lineTo(cx, dy + tile - 10)
          ..lineTo(dx + 10, cy)
          ..close();
        canvas.drawPath(diamond, line);

        // Inner diamond
        final inner = Path()
          ..moveTo(cx, dy + 26)
          ..lineTo(dx + tile - 26, cy)
          ..lineTo(cx, dy + tile - 26)
          ..lineTo(dx + 26, cy)
          ..close();
        canvas.drawPath(inner, line..strokeWidth = 1.6);

        // Small cross flower
        final petal = Paint()..color = TikiyaColors.bleuCyan.withValues(alpha: opacity * 0.65);
        canvas.save();
        canvas.translate(cx, cy);
        for (var i = 0; i < 4; i++) {
          canvas.rotate(math.pi / 2);
          final p = Path()
            ..addRRect(
              RRect.fromRectAndRadius(
                const Rect.fromLTWH(-6, -28, 12, 18),
                const Radius.circular(8),
              ),
            );
          canvas.drawPath(p, petal);
        }
        canvas.restore();

        // Tiny dots grid
        final dot = Paint()..color = Colors.white.withValues(alpha: opacity * 0.45);
        for (var i = 0; i < 3; i++) {
          for (var j = 0; j < 3; j++) {
            canvas.drawCircle(Offset(dx + 18 + i * 18, dy + 18 + j * 18), 1.6, dot);
          }
        }

        // Subtle fill in center occasionally
        if ((r + c) % 2 == 0) {
          final center = Path()
            ..addRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset(cx, cy), width: 22, height: 22),
                const Radius.circular(6),
              ),
            );
          canvas.drawPath(center, fill);
        }
      }
    }

    // Edge highlight
    final edge = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(size.width - 2, 0, 2, size.height), edge);
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}
