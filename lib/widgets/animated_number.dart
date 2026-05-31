import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Animated number display — bounces and changes color on value change.
class AnimatedNumber extends StatefulWidget {
  final int value;
  final bool inverted;     // true = higher is worse (suspicion)
  final Color? baseColor;  // neutral color when not flashing
  final Color? positiveColor;
  final Color? negativeColor;

  const AnimatedNumber({
    super.key,
    required this.value,
    this.inverted = false,
    this.baseColor,
    this.positiveColor,
    this.negativeColor,
  });

  @override
  State<AnimatedNumber> createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<AnimatedNumber> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _colorAnim;
  int _prevValue = -1;

  @override
  void initState() {
    super.initState();
    _prevValue = widget.value;
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _colorAnim = Tween(begin: 0.0, end: 1.0).animate(_ctrl);
    _ctrl.value = 1.0; // start at neutral color, not flash
  }

  @override
  void didUpdateWidget(AnimatedNumber old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _prevValue = old.value;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _barColor => widget.baseColor ?? AppColors.neonGreen;

  @override
  Widget build(BuildContext context) {
    final goingUp = widget.value > _prevValue;
    final isGood = widget.inverted ? !goingUp : goingUp;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Text(
            '${widget.value}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color.lerp(
                isGood ? AppColors.neonGreen : AppColors.neonRed,
                _barColor,
                _colorAnim.value,
              ),
            ),
          ),
        );
      },
    );
  }
}
