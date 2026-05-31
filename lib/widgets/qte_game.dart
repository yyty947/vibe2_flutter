import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/qte_config.dart';
import '../state/theme_provider.dart';
import '../services/audio_manager.dart';
import '../theme/colors.dart';
import 'qte_result_overlay.dart';

class QteGame extends ConsumerStatefulWidget {
  final QteConfig config;
  final int suspicion;
  final bool highRisk;
  final void Function(QteResult result) onComplete;

  const QteGame({
    super.key,
    required this.config,
    required this.suspicion,
    this.highRisk = false,
    required this.onComplete,
  });

  @override
  ConsumerState<QteGame> createState() => _QteGameState();
}

class _QteGameState extends ConsumerState<QteGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _moveCtrl;
  final _containerKey = GlobalKey();
  final _blockKey = GlobalKey();

  QteResult? _result;
  bool _locked = false;
  final _random = Random();

  // Pre-computed random waypoints for phase 2 (25%-70%)
  late final List<Offset> _waypoints;

  // Game area size (set after first layout)
  Size _areaSize = const Size(280, 200);

  // Block size
  static const _blockW = 36.0;
  static const _blockH = 26.0;

  @override
  void initState() {
    super.initState();
    final timeLimit = widget.config.effectiveTimeLimit(widget.suspicion);
    _moveCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: timeLimit),
    );
    _moveCtrl.addListener(() => setState(() {}));
    _moveCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_locked) {
        _onLock(QteResult.miss);
      }
    });

    // Pre-compute random waypoints for the 25%-70% phase
    _waypoints = List.generate(8, (_) => Offset(
      _random.nextDouble() * 0.8 + 0.1, // 0.1-0.9 range
      _random.nextDouble() * 0.8 + 0.1,
    ));

    _moveCtrl.forward();
  }

  Offset _blockPosition(double t) {
    final w = _areaSize.width - _blockW;
    final h = _areaSize.height - _blockH;

    if (t <= 0.25) {
      // Phase 1: horizontal sine, slowly sweeping across center
      final phaseT = t / 0.25;
      final x = (0.5 + 0.2 * sin(phaseT * 4 * pi)) * w;
      final y = (0.5 + 0.15 * sin(phaseT * 3 * pi)) * h;
      return Offset(x, y);
    } else if (t <= 0.70) {
      // Phase 2: step through pre-computed waypoints
      final phaseT = (t - 0.25) / 0.45;
      final idx = (phaseT * (_waypoints.length - 1)).floor();
      final frac = phaseT * (_waypoints.length - 1) - idx;
      final from = _waypoints[idx];
      final to = idx + 1 < _waypoints.length ? _waypoints[idx + 1] : const Offset(0.5, 0.5);
      final x = (from.dx + (to.dx - from.dx) * frac) * w;
      final y = (from.dy + (to.dy - from.dy) * frac) * h;
      return Offset(x, y);
    } else {
      // Phase 3: spiral around center, amplitude decreasing
      final phaseT = (t - 0.70) / 0.30;
      final amp = 0.18 * (1.0 - phaseT * 0.5); // decreasing amplitude
      final angle = phaseT * 2 * pi;
      final x = (0.5 + amp * cos(angle)) * w;
      final y = (0.5 + amp * sin(angle)) * h;
      return Offset(x, y);
    }
  }

  void _onLock(QteResult result) {
    if (_locked) return;
    _locked = true;
    _result = result;
    _moveCtrl.stop();

    // Play SFX based on result
    HapticFeedback.lightImpact();
    if (result == QteResult.perfect) {
      AudioManager().playSfx('success');
    } else if (result == QteResult.good) {
      AudioManager().playSfx('click');
    } else {
      AudioManager().playSfx('alert');
    }

    setState(() {});
  }

  void _onLockPress() {
    if (_locked) return;

    // Get block center in local coordinates
    final containerBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;
    final blockBox = _blockKey.currentContext?.findRenderObject() as RenderBox?;
    if (containerBox == null || blockBox == null) return;

    final blockLocal = containerBox.globalToLocal(blockBox.localToGlobal(Offset.zero));
    final blockCenter = blockLocal + const Offset(_blockW / 2, _blockH / 2);
    final containerCenter = Offset(_areaSize.width / 2, _areaSize.height / 2);

    final offset = (blockCenter - containerCenter).distance;

    final result = offset <= widget.config.perfectThreshold
        ? QteResult.perfect
        : offset <= widget.config.goodThreshold
            ? QteResult.good
            : QteResult.miss;

    _onLock(result);
  }

  @override
  void dispose() {
    _moveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final t = _moveCtrl.value;
    final blockPos = _blockPosition(t);
    final timeLeft = _moveCtrl.duration!.inMilliseconds -
        (_moveCtrl.value * _moveCtrl.duration!.inMilliseconds).round();

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Header
        Row(children: [
          Icon(widget.highRisk ? LucideIcons.shieldAlert : LucideIcons.crosshair,
              size: 9, color: widget.highRisk ? AppColors.neonRed : AppColors.neonCyan),
          const SizedBox(width: 4),
          Text('QTE — 锁定居中',
              style: TextStyle(fontSize: 9,
                  color: widget.highRisk ? AppColors.neonRed : AppColors.neonCyan)),
          const Spacer(),
          // Countdown
          Text('${(timeLeft / 1000).toStringAsFixed(1)}s',
              style: TextStyle(fontSize: 9, fontFamily: 'Share Tech Mono',
                  color: timeLeft < 1500 ? AppColors.neonRed : AppColors.textMuted)),
        ]),
        const SizedBox(height: 4),

        // Game area
        Container(
          key: _containerKey,
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: theme.colors.bgSurface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colors.glassBorder, width: 1),
            image: const DecorationImage(
              image: AssetImage('assets/backgrounds/QTE.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Color(0x55000000), BlendMode.darken),
            ),
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            _areaSize = Size(constraints.maxWidth, constraints.maxHeight);
            return Stack(clipBehavior: Clip.hardEdge, children: [
              // Target zone (center)
              Positioned(
                left: _areaSize.width / 2 - 30,
                top: _areaSize.height / 2 - 22,
                child: IgnorePointer(
                  child: _AnimatedTargetZone(),
                ),
              ),

              // Moving block
              if (!_locked)
                Positioned(
                  left: blockPos.dx,
                  top: blockPos.dy,
                  child: Container(
                    key: _blockKey,
                    width: _blockW,
                    height: _blockH,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.6), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: AppColors.neonGreen.withValues(alpha: 0.25), blurRadius: 8),
                      ],
                    ),
                    child: Text('div',
                        style: TextStyle(fontSize: 12, fontFamily: 'Share Tech Mono',
                            color: AppColors.neonGreen, fontWeight: FontWeight.bold)),
                  ),
                ),
            ]);
          }),
        ),
        const SizedBox(height: 6),

        // Lock button
        _LockButton(
          locked: _locked,
          onTap: _onLockPress,
        ),

        // Result overlay
        if (_result != null)
          QteResultOverlay(
            result: _result!,
            config: widget.config,
            onDismiss: () => widget.onComplete(_result!),
          ),
      ]),
    );
  }
}

/// Pulsing dashed target zone indicator.
class _AnimatedTargetZone extends StatefulWidget {
  @override
  State<_AnimatedTargetZone> createState() => _AnimatedTargetZoneState();
}

class _AnimatedTargetZoneState extends State<_AnimatedTargetZone>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Container(
        width: 60,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppColors.neonCyan.withValues(alpha: 0.35 + 0.35 * _ctrl.value),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Icon(LucideIcons.plus, size: 10,
              color: AppColors.neonCyan.withValues(alpha: 0.25 + 0.25 * _ctrl.value)),
        ),
      ),
    );
  }
}

/// "锁定/居中" button with press-scale + haptic.
class _LockButton extends StatefulWidget {
  final bool locked;
  final VoidCallback onTap;
  const _LockButton({required this.locked, required this.onTap});

  @override
  State<_LockButton> createState() => _LockButtonState();
}

class _LockButtonState extends State<_LockButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.93 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOutCubic,
      child: GestureDetector(
        onTapDown: widget.locked ? null : (_) {
          setState(() => _pressed = true);
          HapticFeedback.lightImpact();
          AudioManager().playSfx('click');
        },
        onTapUp: widget.locked ? null : (_) => setState(() => _pressed = false),
        onTapCancel: widget.locked ? null : () => setState(() => _pressed = false),
        onTap: widget.locked ? null : widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.locked
                ? AppColors.textDim.withValues(alpha: 0.2)
                : AppColors.neonGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: widget.locked
                  ? AppColors.textDim
                  : AppColors.neonGreen.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Text(
            widget.locked ? '已锁定' : '[ 锁定 / 居中 ]',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Share Tech Mono',
              color: widget.locked ? AppColors.textDim : AppColors.neonGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
