import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// CRT scanline overlay — simulates a monitor screen.
/// pointer-events: none, z-index on top.
class CrtOverlay extends StatelessWidget {
  const CrtOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CrtPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _CrtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Scanlines: repeating horizontal lines with 2px spacing
    final scanlinePaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(0, 4),
        [Colors.transparent, Colors.transparent, Colors.black.withAlpha(15), Colors.black.withAlpha(15)],
        [0.0, 0.5, 0.5, 1.0],
        TileMode.repeated,
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), scanlinePaint);

    // Radial vignette (darker edges)
    final vignettePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment.center,
        radius: 0.75,
        colors: [Colors.transparent, Color(0x59000000)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
