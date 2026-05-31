import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../state/providers.dart';
import '../state/theme_provider.dart';
import '../theme/colors.dart';
import '../services/audio_manager.dart';

/// Compact Top Bar HUD for landscape layout (h=28).
class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final theme = ref.watch(themeProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      height: 28,
      decoration: BoxDecoration(
        color: theme.colors.bgPanel,
        border: Border(bottom: BorderSide(color: theme.colors.dividerColor)),
      ),
      padding: const EdgeInsets.only(left: 8, right: 16),
      child: Row(children: [
        Icon(LucideIcons.terminal, size: 11, color: AppColors.neonGreen),
        const SizedBox(width: 4),
        Text('FRONTEND SURVIVAL',
            style: TextStyle(fontFamily: 'Share Tech Mono', fontSize: 10, fontWeight: FontWeight.bold, color: theme.colors.textPrimary)),
        const SizedBox(width: 6),
        Text('|', style: TextStyle(fontSize: 9, color: theme.colors.dividerColor)),
        const SizedBox(width: 6),
        Text('CYCLE ', style: TextStyle(fontSize: 9, color: theme.colors.textMuted)),
        Text('${state.day}', style: TextStyle(fontSize: 9, color: AppColors.neonGreen, fontWeight: FontWeight.bold)),
        Text(' / 30', style: TextStyle(fontSize: 9, color: theme.colors.textMuted)),
        const SizedBox(width: 6),
        Text('|', style: TextStyle(fontSize: 9, color: theme.colors.dividerColor)),
        const SizedBox(width: 6),
        Text(state.phase.label, style: TextStyle(fontSize: 8, color: theme.colors.textMuted)),
        const Spacer(),
        Consumer(builder: (context, ref, _) {
          final muted = ref.watch(audioProvider.select((a) => a.muted));
          return GestureDetector(
            onTap: () {
              AudioManager().playSfx('click');
              ref.read(audioProvider.notifier).toggleMute();
              final a = ref.read(audioProvider);
              AudioManager().sync(muted: a.muted, bgmVolume: a.bgmVolume, sfxVolume: a.sfxVolume);
            },
            child: Icon(muted ? LucideIcons.volumeX : LucideIcons.volume2, size: 10, color: theme.colors.textMuted),
          );
        }),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => ref.read(gameProvider.notifier).restart(),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(LucideIcons.rotateCcw, size: 8, color: theme.colors.textMuted),
            const SizedBox(width: 2),
            Text('RESTART', style: TextStyle(fontSize: 8, color: theme.colors.textMuted)),
          ]),
        ),
      ]),
    );
  }
}
