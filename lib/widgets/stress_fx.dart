import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Red inner shadow pulse when energy < 20 (UI_DESIGN_SYSTEM §6).
class StressFx extends StatefulWidget {
  final bool active;
  final Widget child;

  const StressFx({super.key, required this.active, required this.child});

  @override
  State<StressFx> createState() => _StressFxState();
}

class _StressFxState extends State<StressFx> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppColors.neonRed.withAlpha((t * 80 + 20).toInt()),
                blurRadius: t * 50 + 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
