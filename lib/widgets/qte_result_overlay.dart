import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/qte_config.dart';
import '../theme/colors.dart';

class QteResultOverlay extends StatefulWidget {
  final QteResult result;
  final QteConfig config;
  final VoidCallback onDismiss;

  const QteResultOverlay({
    super.key,
    required this.result,
    required this.config,
    required this.onDismiss,
  });

  @override
  State<QteResultOverlay> createState() => _QteResultOverlayState();
}

class _QteResultOverlayState extends State<QteResultOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPerfect = widget.result == QteResult.perfect;
    final isGood = widget.result == QteResult.good;
    final isMiss = widget.result == QteResult.miss;

    final accentColor = isPerfect ? AppColors.neonGreen
        : isGood ? AppColors.neonAmber : AppColors.neonRed;
    final label = isPerfect ? 'PERFECT' : isGood ? 'GOOD' : 'MISS';
    final subtitle = isPerfect
        ? '像素级居中！不愧是 CSS 大师'
        : isGood
            ? 'margin: 0 auto 勉强能看'
            : widget.config.tauntPool[_random.nextInt(widget.config.tauntPool.length)];
    final icon = isPerfect ? LucideIcons.sparkles
        : isGood ? LucideIcons.target : LucideIcons.unlink;

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onDismiss(),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, child) {
            final value = _anim.value;
            return Stack(children: [
              // Particles for Perfect
              if (isPerfect) ..._buildParticles(value, accentColor),

              // Pulse ring for Good
              if (isGood)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 80 + 120 * value,
                      height: 60 + 90 * value,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.6 * (1 - value)),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),

              // Flash for Miss
              if (isMiss)
                Positioned.fill(
                  child: Container(
                    color: AppColors.neonRed.withValues(alpha: 0.15 * (1 - value)),
                  ),
                ),

              // Central text
              Center(
                child: Opacity(
                  opacity: (value * 1.2).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D0D).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.5 + 0.3 * value),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.2 * value),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(icon, color: accentColor, size: 16),
                        const SizedBox(height: 4),
                        Text(label,
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Share Tech Mono',
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            )),
                        const SizedBox(height: 2),
                        SizedBox(
                          width: 180,
                          child: Text(subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 9, color: AppColors.textMuted, height: 1.3)),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),

              // Tap to continue hint — placed well below the result card
              Positioned(
                bottom: 16,
                left: 0, right: 0,
                child: Center(
                  child: Opacity(
                    opacity: (value * 1.5).clamp(0.0, 0.5),
                    child: Text('点击继续',
                        style: TextStyle(fontSize: 8, color: AppColors.textDim)),
                  ),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  List<Widget> _buildParticles(double value, Color color) {
    final particles = <Widget>[];
    for (int i = 0; i < 18; i++) {
      final angle = (i / 18) * 2 * pi;
      final dist = 30 + 60 * value;
      final dx = cos(angle) * dist;
      final dy = sin(angle) * dist;
      final size = 3.0 + 3.0 * value * _random.nextDouble();
      particles.add(
        Positioned(
          left: MediaQuery.of(context).size.width / 2 + dx - size / 2,
          top: MediaQuery.of(context).size.height / 2 + dy - size / 2,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i.isEven ? color : AppColors.neonCyan,
            ),
          ),
        ),
      );
    }
    return particles;
  }
}
