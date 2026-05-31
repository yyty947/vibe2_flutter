import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../data/game_data.dart';
import '../services/audio_manager.dart';
import '../services/save_service.dart';
import '../state/providers.dart';
import '../theme/colors.dart';

/// Two-phase ending screen: glitch, then reveal.
class EndingScreen extends ConsumerStatefulWidget {
  const EndingScreen({super.key});

  @override
  ConsumerState<EndingScreen> createState() => _EndingScreenState();
}

class _EndingScreenState extends ConsumerState<EndingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _crashAddr =
      '0x${Random().nextInt(0xFFFFFFFF).toRadixString(16).toUpperCase().padLeft(8, '0')}';

  static const _endings = <String, _EndingConfig>{
    'BE_DEATH': _EndingConfig(
      'SYSTEM FAILURE',
      AppColors.neonRed,
      LucideIcons.skull,
      true,
    ),
    'BE_FIRED': _EndingConfig(
      'TERMINATED',
      AppColors.neonRed,
      LucideIcons.doorOpen,
      true,
    ),
    'GE_OFFER': _EndingConfig(
      'CONNECTION ESTABLISHED',
      AppColors.neonGreen,
      LucideIcons.rocket,
      false,
    ),
    'NE_PEACE': _EndingConfig(
      'PROCESS COMPLETE',
      AppColors.neonAmber,
      LucideIcons.checkCircle,
      false,
    ),
    'HE_KING': _EndingConfig(
      'SYSTEM OVERRIDE SUCCESS',
      AppColors.neonCyan,
      LucideIcons.crown,
      false,
    ),
  };

  @override
  void initState() {
    super.initState();
    final ending = ref.read(gameProvider).ending;
    final isBad = ending == 'BE_DEATH' || ending == 'BE_FIRED';
    _ctrl =
        AnimationController(
            vsync: this,
            duration: Duration(milliseconds: isBad ? 800 : 400),
          )
          ..forward().then((_) {
            SaveService.clear();
          });
    AudioManager().playSfx(isBad ? 'glitch' : 'success');
    AudioManager().playBgm(null);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    if (state.ending == null) return const SizedBox.shrink();

    final config = _endings[state.ending] ?? _endings['BE_FIRED']!;
    final isBad = config.isBad;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        if (_ctrl.value < 1.0) {
          return _GlitchPhase(isBad: isBad, crashAddr: _crashAddr);
        }
        return _RevealPhase(
          config: config,
          state: state,
          onRestart: () => ref.read(gameProvider.notifier).restart(),
        );
      },
    );
  }
}

class _GlitchPhase extends StatelessWidget {
  final bool isBad;
  final String crashAddr;

  const _GlitchPhase({required this.isBad, required this.crashAddr});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgDeep,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isBad ? 'FATAL ERROR' : 'COMPLETED',
              style: TextStyle(
                fontFamily: 'Share Tech Mono',
                fontSize: 32,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: AppColors.neonMagenta.withAlpha(100),
                    blurRadius: 4,
                    offset: const Offset(2, 0),
                  ),
                  Shadow(
                    color: AppColors.neonCyan.withAlpha(100),
                    blurRadius: 4,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isBad ? 'CRASH_DUMP_$crashAddr' : 'FINALIZING...',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevealPhase extends StatelessWidget {
  final _EndingConfig config;
  final dynamic state;
  final VoidCallback onRestart;

  const _RevealPhase({
    required this.config,
    required this.state,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final ending = state.ending as String;
    final data = GameData.endings[ending] ?? GameData.endings['BE_FIRED']!;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          colors: [
            config.isBad
                ? AppColors.neonRed.withAlpha(20)
                : AppColors.neonGreen.withAlpha(12),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(config.icon, size: 14, color: config.color),
                  const SizedBox(width: 6),
                  Text(
                    config.tag,
                    style: TextStyle(
                      fontFamily: 'Share Tech Mono',
                      fontSize: 11,
                      color: config.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                data['title']!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Share Tech Mono',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 24, height: 1, color: AppColors.borderDim),
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 24, height: 1, color: AppColors.borderDim),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data['text']!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary.withAlpha(190),
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgPanel,
                  border: Border.all(color: AppColors.borderDim),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Text(
                      'SURVIVAL REPORT',
                      style: TextStyle(
                        fontSize: 8,
                        color: AppColors.textMuted,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatRow('Cycles', '${state.day}'),
                    _StatRow('Code', '${state.actionStats.writeCode}'),
                    _StatRow('Bugfix', '${state.actionStats.fixBug}'),
                    _StatRow('Study', '${state.actionStats.studyInterview}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  AudioManager().playSfx('click');
                  onRestart();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 32,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    border: Border.all(
                      color: AppColors.neonGreen.withAlpha(80),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '[ RESTART ]',
                    style: TextStyle(
                      fontFamily: 'Fira Code',
                      fontSize: 13,
                      color: AppColors.neonGreen,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 10, color: AppColors.neonGreen),
          ),
        ],
      ),
    );
  }
}

class _EndingConfig {
  final String tag;
  final Color color;
  final IconData icon;
  final bool isBad;

  const _EndingConfig(this.tag, this.color, this.icon, this.isBad);
}
