import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import '../services/audio_manager.dart';
import '../services/save_service.dart';
import '../theme/colors.dart';
import '../widgets/matrix_rain.dart';
import 'tutorial_screen.dart';

/// Title screen with Matrix rain, ASCII art, New/Continue buttons.
class TitleScreen extends ConsumerStatefulWidget {
  const TitleScreen({super.key});

  @override
  ConsumerState<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends ConsumerState<TitleScreen> {
  bool _hasSave = false;
  int? _savedDay;
  int? _savedAt;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _checkSave();
    AudioManager().playBgm('title');
  }

  Future<void> _checkSave() async {
    final state = await SaveService.load();
    if (mounted) {
      setState(() {
        _hasSave = state != null;
        _savedDay = state?.day;
        _savedAt = state?.savedAt;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Matrix rain background (paused when tutorial is open)
      Positioned.fill(child: MatrixRain(paused: _showTutorial)),
      // Dark overlay for readability
      Positioned.fill(child: Container(color: AppColors.bgDeep.withAlpha(180))),
      // Content
      Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Title
          Text('前端生死劫',
              style: TextStyle(fontFamily: 'Share Tech Mono', fontSize: 28, fontWeight: FontWeight.bold,
                  color: AppColors.neonGreen, letterSpacing: 6,
                  shadows: [Shadow(color: AppColors.neonGreen.withAlpha(180), blurRadius: 12)])),
          const SizedBox(height: 6),
          Text('Frontend Survival',
              style: TextStyle(fontFamily: 'Share Tech Mono', fontSize: 12,
                  color: AppColors.neonCyan, letterSpacing: 4,
                  shadows: [Shadow(color: AppColors.neonCyan.withAlpha(120), blurRadius: 10)])),
          const SizedBox(height: 4),
          Text('v1.3.0 // CYBERPUNK TERMINAL EDITION',
              style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
          const SizedBox(height: 24),

          // Subtitle
          Text.rich(TextSpan(children: [
            TextSpan(text: '\$ ', style: TextStyle(color: AppColors.neonGreen, fontFamily: 'Fira Code')),
            TextSpan(text: '2026年，互联网大厂，降本增效\n', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            TextSpan(text: '\$ ', style: TextStyle(color: AppColors.neonGreen)),
            TextSpan(text: '你是一名P6前端开发\n', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            TextSpan(text: '\$ ', style: TextStyle(color: AppColors.neonGreen)),
            TextSpan(text: '距离审判日还有 ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            TextSpan(text: '30', style: TextStyle(fontSize: 11, color: AppColors.neonCyan)),
            TextSpan(text: ' 天', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ])),
          const SizedBox(height: 32),

          // [ NEW GAME ]
          _CyberButton(
            label: 'NEW GAME',
            color: AppColors.neonGreen,
            onTap: () async {
              await SaveService.clear();
              ref.read(gameProvider.notifier).startIntroVideo();
            },
          ),
          const SizedBox(height: 12),

          // [ CONTINUE ] (only if save exists)
          if (_hasSave)
            _CyberButton(
              label: 'CONTINUE',
              color: AppColors.neonCyan,
              onTap: () async {
                final saved = await SaveService.load();
                if (saved != null) {
                  ref.read(gameProvider.notifier).continueGameFrom(saved);
                }
              },
            ),
          const SizedBox(height: 12),

          // [ 玩法介绍 ]
          _CyberButton(
            label: 'GUIDE',
            color: AppColors.neonAmber,
            onTap: () => setState(() => _showTutorial = true),
          ),
          const SizedBox(height: 12),

          // Save info
          if (_hasSave && _savedAt != null)
            Text('SAVE  Day $_savedDay  ${_formatTime(_savedAt!)}',
                style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
        ]),
      )),
      // Tutorial overlay with transition
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => ScaleTransition(
          scale: Tween(begin: 0.95, end: 1.0).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: _showTutorial
            ? Positioned.fill(
                key: const ValueKey('tutorial'),
                child: TutorialScreen(onBack: () => setState(() => _showTutorial = false)),
              )
            : const SizedBox(key: ValueKey('none')),
      ),
    ]);
  }

  String _formatTime(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Cyberpunk-style button: [ LABEL ] with press-scale + haptic.
class _CyberButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CyberButton({required this.label, required this.color, required this.onTap});

  @override
  State<_CyberButton> createState() => _CyberButtonState();
}

class _CyberButtonState extends State<_CyberButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOutCubic,
        child: GestureDetector(
          onTapDown: (_) {
            setState(() => _pressed = true);
            HapticFeedback.lightImpact();
            AudioManager().playSfx('click');
          },
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border.all(color: widget.color.withAlpha(80)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '[ ', style: TextStyle(color: widget.color, fontFamily: 'Fira Code', fontSize: 13)),
              TextSpan(text: widget.label, style: TextStyle(color: widget.color, fontFamily: 'Fira Code', fontSize: 13)),
              TextSpan(text: ' ]', style: TextStyle(color: widget.color, fontFamily: 'Fira Code', fontSize: 13)),
            ])),
          ),
        ),
      ),
    );
  }
}
