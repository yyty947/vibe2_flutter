import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../state/providers.dart';
import '../data/game_data.dart';
import '../theme/colors.dart';

/// Buff/Debuff icon bar (TECH_ARCH §8.4).
class BuffBar extends ConsumerWidget {
  const BuffBar({super.key});

  static const _icons = <String, IconData>{
    'ShieldCheck': LucideIcons.shieldCheck,
    'Zap': LucideIcons.zap,
    'Star': LucideIcons.star,
    'Crown': LucideIcons.crown,
    'EyeOff': LucideIcons.eyeOff,
    'ShieldAlert': LucideIcons.shieldAlert,
    'BatteryWarning': LucideIcons.batteryWarning,
    'HeartCrack': LucideIcons.heartCrack,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(gameProvider.select((s) => s.activeStatuses));
    if (active.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 4, runSpacing: 4, children: active.map((id) {
      final cond = GameData.statusConditions.where((c) => c.id == id).firstOrNull;
      if (cond == null) return const SizedBox.shrink();
      final isBuff = cond.isBuff;
      final icon = _icons[cond.icon] ?? LucideIcons.shieldCheck;

      return Tooltip(
        richMessage: WidgetSpan(child: SizedBox(width: 180, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
          children: [
            Text(cond.tooltip.title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                color: isBuff ? AppColors.neonGreen : AppColors.neonRed)),
            const SizedBox(height: 4),
            Text(cond.tooltip.effect, style: TextStyle(fontSize: 10, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(cond.tooltip.flavor, style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
          ]))),
        child: Container(
          width: 28, height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isBuff ? AppColors.neonGreen.withAlpha(20) : AppColors.neonRed.withAlpha(20),
            border: Border.all(color: isBuff ? AppColors.neonGreen.withAlpha(100) : AppColors.neonRed.withAlpha(100)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 14, color: isBuff ? AppColors.neonGreen : AppColors.neonRed),
        ),
      );
    }).toList());
  }
}
