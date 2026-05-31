import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#\$%&*<>{}[]|/\\';
const _fontSize = 14.0;
const _trailLen = 6;

/// Matrix digital rain effect (UI_DESIGN_SYSTEM §5.6).
class MatrixRain extends StatefulWidget {
  final bool paused;
  const MatrixRain({super.key, this.paused = false});

  @override
  State<MatrixRain> createState() => _MatrixRainState();
}

class _MatrixRainState extends State<MatrixRain> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _rng = Random();
  final _drops = <double>[];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120))
      ..addListener(() => setState(() {}));
    if (!widget.paused) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(MatrixRain old) {
    super.didUpdateWidget(old);
    if (widget.paused != old.paused) {
      if (widget.paused) {
        _ctrl.stop();
      } else {
        _ctrl.repeat();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MatrixPainter(_rng, _drops, repaint: _ctrl), size: Size.infinite);
  }
}

class _MatrixPainter extends CustomPainter {
  final Random _rng;
  final List<double> _drops;

  _MatrixPainter(this._rng, this._drops, {required Listenable repaint}) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final cols = (size.width / _fontSize).ceil();
    while (_drops.length < cols) {
      _drops.add(_rng.nextDouble() * -50);
    }

    // Fade
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0x0D0D0D0D));

    for (int i = 0; i < cols && i < _drops.length; i++) {
      final x = i * _fontSize;
      final y = _drops[i] * _fontSize;

      if (y > 0 && y < size.height) {
        _drawChar(canvas, x, y, AppColors.neonGreen.withAlpha(230));
        for (int j = 1; j <= _trailLen; j++) {
          final ty = y - j * _fontSize;
          if (ty > 0 && ty < size.height) {
            final alpha = (0.3 * (1 - j / _trailLen) * 255).toInt().clamp(0, 255);
            _drawChar(canvas, x, ty, AppColors.neonGreen.withAlpha(alpha));
          }
        }
      }

      _drops[i] += 0.5 + _rng.nextDouble() * 0.5;
      if (_drops[i] * _fontSize > size.height && _rng.nextDouble() > 0.975) {
        _drops[i] = 0;
      }
    }
  }

  void _drawChar(Canvas canvas, double x, double y, Color color) {
    final ch = _chars[_rng.nextInt(_chars.length)];
    final tp = TextPainter(
      text: TextSpan(text: ch, style: TextStyle(color: color, fontSize: _fontSize, fontFamily: 'Fira Code')),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
