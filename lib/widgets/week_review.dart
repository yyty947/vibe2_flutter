import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../state/providers.dart';
import '../data/game_data.dart';
import '../services/audio_manager.dart';
import '../theme/colors.dart';
import 'sidebar.dart' show showInfoPopup, formatSkillEffects, skillIcons;

/// Weekly review modal (Day 7/14/21).
class WeekReview extends ConsumerStatefulWidget {
  const WeekReview({super.key});

  @override
  ConsumerState<WeekReview> createState() => _WeekReviewState();
}

class _WeekReviewState extends ConsumerState<WeekReview> {
  String? _pendingUndoSkillId;

  static const _branchColors = <String, Color>{
    'energy': AppColors.neonGreen, 'tech': AppColors.neonCyan,
    'social': AppColors.neonAmber, 'interview': AppColors.neonMagenta,
  };

  static const _branchLabels = <String, String>{
    'energy': '精力管理', 'tech': '代码效率', 'social': '社交技巧', 'interview': '面试精进',
  };

  @override
  Widget build(BuildContext context) {
    final show = ref.watch(gameProvider.select((s) => s.showWeekReview));
    if (!show) return const SizedBox.shrink();

    final state = ref.watch(gameProvider);
    final day = state.day;
    final weekLabel = day <= 8 ? '第一周' : day <= 15 ? '第二周' : '第三周';

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/backgrounds/office-politics.png',
              fit: BoxFit.cover,
              errorBuilder: (_, e, _) => const SizedBox.shrink()),
        ),
        Container(
          color: AppColors.bgDeep.withValues(alpha: 0.75),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.9 + 0.1 * value,
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgPanel, borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderDim),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Header
            Row(children: [
              Text('CYCLES ${day - 7}-${day - 1} COMPLETED',
                  style: TextStyle(fontSize: 7, color: AppColors.textMuted, fontFamily: 'Share Tech Mono')),
              const Spacer(),
              Row(children: [
                Icon(LucideIcons.coins, size: 10, color: AppColors.neonAmber),
                const SizedBox(width: 3),
                Text('${state.skillPoints}pt',
                    style: TextStyle(fontSize: 10, color: AppColors.neonAmber)),
              ]),
            ]),
            const SizedBox(height: 6),
            Text('$weekLabel回顾', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                fontFamily: 'Share Tech Mono', color: AppColors.neonGreen)),
            const SizedBox(height: 6),
            if (_pendingUndoSkillId != null)
              GestureDetector(
                onTap: () => setState(() => _pendingUndoSkillId = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: AppColors.neonRed.withAlpha(15),
                    border: Border.all(color: AppColors.neonRed.withAlpha(100)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text('点击 [继续] 关闭面板将取消撤销', style: TextStyle(fontSize: 7, color: AppColors.neonRed)),
                ),
              ),
            const SizedBox(height: 2),

            // Stat summary
            Row(children: ['精力', 'KPI', '面试度', '怀疑度'].map((l) {
              final v = l == '精力' ? state.energy : l == 'KPI' ? state.kpi
                  : l == '面试度' ? state.interview : state.suspicion;
              final c = l == '怀疑度' ? AppColors.neonRed
                  : l == '面试度' ? AppColors.neonAmber
                  : l == 'KPI' ? AppColors.neonCyan : AppColors.neonGreen;
              return Expanded(child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.bgDeep, borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.borderDim)),
                  child: Column(children: [
                    Text(l, style: TextStyle(fontSize: 7, color: AppColors.textMuted)),
                    Text('$v', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c)),
                  ]),
                ),
              ));
            }).toList()),
            const SizedBox(height: 10),

            // Skill tree (4 columns)
            Row(crossAxisAlignment: CrossAxisAlignment.start,
                children: ['energy', 'tech', 'social', 'interview'].map((branch) {
              final branchSkills = GameData.skills.where((s) => s.branch == branch).toList()
                ..sort((a, b) => a.tier.compareTo(b.tier));
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(children: [
                  Text(_branchLabels[branch]!, style: TextStyle(fontSize: 7, fontFamily: 'Share Tech Mono',
                      color: _branchColors[branch])),
                  const SizedBox(height: 2),
                  ...branchSkills.map((sk) => _SkillNode(
                    skill: sk,
                    pendingUndoId: _pendingUndoSkillId,
                    onUndoPending: (id) => setState(() => _pendingUndoSkillId = id),
                    onUndoExec: (id) {
                      ref.read(gameProvider.notifier).refundSkill(id);
                      setState(() => _pendingUndoSkillId = null);
                    },
                  )),
                ]),
              ));
            }).toList()),
            const SizedBox(height: 10),

            // SOCIAL_T2 special action
            if (state.skills.contains('SOCIAL_T2'))
              _SocialAction(),

            // Close
            _WeekButton(
              onTap: () {
                setState(() => _pendingUndoSkillId = null);
                ref.read(gameProvider.notifier).closeWeekReview();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 24),
                decoration: BoxDecoration(border: Border.all(color: AppColors.neonGreen.withAlpha(80)),
                    borderRadius: BorderRadius.circular(4)),
                child: Text('[ 继续 ]', style: TextStyle(fontSize: 11, fontFamily: 'Fira Code', color: AppColors.neonGreen)),
              ),
            ),
          ]),
            ),
          ),
        )),
        ),
      ],
    );
  }
}

class _SkillNode extends ConsumerStatefulWidget {
  final dynamic skill;
  final String? pendingUndoId;
  final void Function(String) onUndoPending;
  final void Function(String) onUndoExec;

  const _SkillNode({
    required this.skill,
    required this.pendingUndoId,
    required this.onUndoPending,
    required this.onUndoExec,
  });

  @override
  ConsumerState<_SkillNode> createState() => _SkillNodeState();
}

class _SkillNodeState extends ConsumerState<_SkillNode> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final owned = ref.watch(gameProvider.select((s) => s.skills.contains(widget.skill.id as String)));
    final points = ref.watch(gameProvider.select((s) => s.skillPoints));
    final skills = ref.watch(gameProvider.select((s) => s.skills));

    final req = widget.skill.requires as String?;
    final hasReq = req == null || skills.contains(req);
    final purchasable = !owned && points >= (widget.skill.cost as int) && hasReq;
    final icon = skillIcons[widget.skill.icon as String] ?? LucideIcons.star;
    final isPendingUndo = owned && widget.pendingUndoId == widget.skill.id;

    void showInfo() {
      showInfoPopup(context,
        title: widget.skill.name as String,
        effect: formatSkillEffects(widget.skill.effects as Map<String, double>),
        flavor: widget.skill.description as String,
        color: owned ? AppColors.neonGreen : AppColors.neonAmber,
      );
    }

    void handleTap() {
      if (owned) {
        if (isPendingUndo) {
          widget.onUndoExec(widget.skill.id as String);
        } else {
          widget.onUndoPending(widget.skill.id as String);
        }
      } else if (purchasable) {
        ref.read(gameProvider.notifier).purchaseSkill(widget.skill.id as String);
      }
    }

    return AnimatedScale(
      scale: _isPressed ? 0.93 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOutCubic,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          HapticFeedback.lightImpact();
          AudioManager().playSfx('click');
        },
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onLongPress: showInfo,
        onTap: handleTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isPendingUndo ? AppColors.neonRed.withAlpha(20)
              : owned ? AppColors.neonGreen.withAlpha(10)
              : purchasable ? AppColors.bgSurface : AppColors.bgDeep,
          border: Border.all(color: isPendingUndo ? AppColors.neonRed.withAlpha(180)
              : owned ? AppColors.neonGreen.withAlpha(100)
              : purchasable ? AppColors.neonAmber.withAlpha(80) : AppColors.borderDim),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Column(children: [
          if (isPendingUndo) ...[
            Icon(LucideIcons.undo, size: 10, color: AppColors.neonRed),
            Text('再次点击撤销', textAlign: TextAlign.center, style: TextStyle(fontSize: 6, color: AppColors.neonRed)),
          ] else ...[
            Icon(icon, size: 10, color: owned ? AppColors.neonGreen : purchasable ? AppColors.neonAmber : AppColors.textDim),
            Text(widget.skill.name as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 6,
                color: owned ? AppColors.neonGreen : purchasable ? AppColors.textPrimary : AppColors.textDim,
                fontWeight: owned ? FontWeight.bold : FontWeight.normal)),
            if (owned)
              Icon(LucideIcons.check, size: 7, color: AppColors.neonGreen)
            else if (purchasable)
              Text('${widget.skill.cost}pt', style: TextStyle(fontSize: 6, color: AppColors.neonAmber))
            else
              Icon(LucideIcons.lock, size: 6, color: AppColors.textDim),
          ],
        ]),
      ),
    ));
  }
}

class _SocialAction extends ConsumerWidget {
  const _SocialAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pts = ref.watch(gameProvider.select((s) => s.skillPoints));
    final sus = ref.watch(gameProvider.select((s) => s.suspicion));
    final canUse = pts >= 3 && sus > 10;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(border: Border.all(color: AppColors.neonAmber.withAlpha(60)),
            borderRadius: BorderRadius.circular(3), color: AppColors.neonAmber.withAlpha(8)),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('请同事喝咖啡（降低怀疑度）', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.neonAmber)),
            Text('消耗 3 成长点，降低 10 点怀疑度', style: TextStyle(fontSize: 7, color: AppColors.textMuted)),
          ])),
          _WeekButton(
            onTap: canUse ? () => ref.read(gameProvider.notifier).spendPointsForSuspicion() : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: canUse ? AppColors.neonAmber.withAlpha(120) : AppColors.borderDim),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text('3pt → SUS -10', style: TextStyle(fontSize: 7,
                  color: canUse ? AppColors.neonAmber : AppColors.textDim)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _WeekButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _WeekButton({required this.child, this.onTap});

  @override
  State<_WeekButton> createState() => _WeekButtonState();
}

class _WeekButtonState extends State<_WeekButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.93 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOutCubic,
      child: GestureDetector(
        onTapDown: widget.onTap == null ? null : (_) {
          setState(() => _pressed = true);
          HapticFeedback.lightImpact();
          AudioManager().playSfx('click');
        },
        onTapUp: widget.onTap == null ? null : (_) => setState(() => _pressed = false),
        onTapCancel: widget.onTap == null ? null : () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: widget.child,
      ),
    );
  }
}
