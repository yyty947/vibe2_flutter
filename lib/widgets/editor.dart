import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../state/providers.dart';
import '../state/theme_provider.dart';
import '../theme/colors.dart';
import '../models/ending_type.dart';
import '../models/action_def.dart';
import '../models/game_event.dart' show EventOption;
import '../data/game_data.dart';
import '../logic/action_pool.dart';
import '../logic/action_resolver.dart' show resolveActionEffects;
import '../services/audio_manager.dart';
import 'typewriter_text.dart';
import 'qte_game.dart';
import 'week_review.dart';

/// Glassmorphism panel — frosted glass effect for floating UI cards.
///
/// Must be placed inside a Stack with a background behind it
/// for BackdropFilter to sample from.
/// Glassmorphism panel — frosted glass effect for floating UI cards.
///
/// Must be placed inside a Stack with a background behind it
/// for BackdropFilter to sample from.
class GlassPanel extends ConsumerWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final Color? bgColor;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.padding,
    this.constraints,
    this.bgColor,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            constraints: constraints,
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: bgColor ?? theme.colors.glassOverlay,
              border: border ?? Border.all(color: theme.colors.glassBorder, width: 1),
              boxShadow: boxShadow,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Simple press-scale button with haptic feedback.
class _TapButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _TapButton({required this.child, this.onTap});

  @override
  State<_TapButton> createState() => _TapButtonState();
}

class _TapButtonState extends State<_TapButton> {
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

/// Shared pop-in animation: scale 0.9→1.0 + fade 0→1, after a configurable delay.
class _PopIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _PopIn({required this.child, this.delayMs = 300});

  @override
  State<_PopIn> createState() => _PopInState();
}

class _PopInState extends State<_PopIn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
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
      builder: (context, child) {
        final value = _ctrl.value;
        return Transform.scale(
          scale: 0.9 + 0.1 * value,
          // Min opacity 0.01 prevents Flutter from discarding the BackdropFilter layer
          child: Opacity(opacity: 0.01 + 0.99 * value, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Central editor area — renders phase-specific content.
class Editor extends ConsumerWidget {
  const Editor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showWeekReview = ref.watch(gameProvider.select((s) => s.showWeekReview));
    if (showWeekReview) return const WeekReview();

    final phase = ref.watch(gameProvider.select((s) => s.phase));
    final interruption = ref.watch(gameProvider.select((s) => s.interruption));
    final currentEventId = ref.watch(gameProvider.select((s) => s.currentEventId));

    // Determine background image (crisp, no blur applied here)
    String? bgImage;
    if (phase == GamePhase.event && currentEventId != null) {
      final ev = GameData.events.where((e) => e.id == currentEventId).firstOrNull;
      if (ev != null && ev.qteConfig != null) {
        bgImage = 'assets/backgrounds/daily-work.png';
      } else if (ev != null && ev.highRisk) {
        bgImage = 'assets/backgrounds/high-risk.png';
      } else {
        final cat = GameData.categoryForEvent(currentEventId);
        if (cat != null) bgImage = 'assets${cat.background}';
      }
    } else if (phase == GamePhase.opening) {
      bgImage = 'assets/backgrounds/morning.png';
    } else if (phase == GamePhase.morning) {
      bgImage = 'assets/backgrounds/morning.png';
    } else if (phase == GamePhase.afternoon) {
      bgImage = 'assets/backgrounds/afternoon.png';
    }

    final content = switch (phase) {
      GamePhase.opening => const OpeningContent(),
      GamePhase.morning || GamePhase.afternoon when interruption != null =>
          const InterruptionContent(),
      GamePhase.morning || GamePhase.afternoon => const ActionContent(),
      GamePhase.event when currentEventId != null => const EventContent(),
      GamePhase.event => const _PhaseLabel('EVENT — Sampling...'),
      GamePhase.settlement => const SettlementContent(),
      _ => const SizedBox.shrink(),
    };

    // Build a unique key so AnimatedSwitcher can crossfade between phases
    final phaseKey = ValueKey('$phase${interruption ?? ''}${currentEventId ?? ''}');

    final animatedContent = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: Tween(begin: 0.9, end: 1.0).animate(anim),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: SizedBox.expand(key: phaseKey, child: content),
    );

    final theme = ref.watch(themeProvider);

    // Background image with crossfade — always in the Stack so transitions animate
    final bgKey = ValueKey(bgImage ?? 'none');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      color: theme.colors.bgDeep,
      child: Stack(children: [
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: SizedBox.expand(
              key: bgKey,
              child: bgImage != null
                  ? Image.asset(bgImage, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink())
                  : Container(color: AppColors.bgDeep),
            ),
          ),
        ),
        animatedContent,
      ]),
    );
  }
}

// ============================================================
// Opening
// ============================================================

class OpeningContent extends ConsumerStatefulWidget {
  const OpeningContent({super.key});

  @override
  ConsumerState<OpeningContent> createState() => _OpeningContentState();
}

class _OpeningContentState extends ConsumerState<OpeningContent> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final modifierId = state.dayModifier;
    final modifier = modifierId != null
        ? GameData.modifiers.where((m) => m.id == modifierId).firstOrNull
        : null;
    final pressId = state.suspicionPressure;
    final press = pressId != null
        ? GameData.pressureEvents.where((p) => p.id == pressId).firstOrNull
        : null;

    if (press != null) {
      return _PressureDialog(pressureEvent: press);
    }

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
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
        onTap: () {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) ref.read(gameProvider.notifier).skipOpening();
          });
        },
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: GlassPanel(
                borderRadius: 8,
                padding: const EdgeInsets.all(20),
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('DAY-${state.day.toString().padLeft(2, '0')} / CYCLE-30',
                        style: TextStyle(fontFamily: 'Share Tech Mono', fontSize: 14, color: AppColors.neonGreen)),
                    if (modifier != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(border: Border.all(color: AppColors.neonAmber.withAlpha(80)),
                            borderRadius: BorderRadius.circular(3), color: AppColors.neonAmber.withAlpha(10)),
                        child: Text('[${modifier.label}] ${modifier.description}',
                            style: TextStyle(fontSize: 10, color: AppColors.neonAmber)),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TypewriterText(
                      text: GameData.openings[state.day.toString()] ?? 'Day ${state.day}。',
                      speed: 25,
                      style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Text('[ TAP TO SKIP ]', style: TextStyle(fontSize: 9, color: AppColors.neonGreen)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

// ============================================================
// Pressure
// ============================================================

class _PressureDialog extends ConsumerWidget {
  final dynamic pressureEvent;
  const _PressureDialog({required this.pressureEvent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pe = pressureEvent;
    return Center(child: Padding(
      padding: const EdgeInsets.all(16),
      child: GlassPanel(
        borderRadius: 8,
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 360),
        border: Border.all(color: AppColors.neonRed.withAlpha(150)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Icon(LucideIcons.alertTriangle, size: 11, color: AppColors.neonRed),
            const SizedBox(width: 6),
            Expanded(child: Text(pe.title as String,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.neonRed))),
          ]),
          const SizedBox(height: 8),
          Text(pe.description as String, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          _TapButton(
            onTap: () => ref.read(gameProvider.notifier).acknowledgePressure(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.neonRed.withAlpha(80)),
                  borderRadius: BorderRadius.circular(3)),
              child: Text('[ 知道了 ]', style: TextStyle(fontSize: 10, color: AppColors.neonRed)),
            ),
          ),
        ]),
      ),
    ));
  }
}

// ============================================================
// Action — 2×2 equal-size grid
// ============================================================

class ActionContent extends ConsumerWidget {
  const ActionContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final phase = state.phase;
    final label = phase == GamePhase.morning ? 'MORNING ACTION' : 'AFTERNOON ACTION';
    final pool = sampleActionPool(state, GameData.actions, state.skills);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Text(label, style: TextStyle(fontFamily: 'Share Tech Mono', fontSize: 11, color: AppColors.neonGreen)),
        const SizedBox(height: 10),
        Expanded(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: _PopIn(
            delayMs: 500,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
              child: GridView.count(
                physics: const ClampingScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: pool.map((a) => _ActionCard(action: a, state: state)).toList(),
              ),
            ),
          ),
        ))),
      ]),
    );
  }
}

// ---- Action card helpers ----

const _actionMeta = <String, _CardMeta>{
  'WRITE_CODE': _CardMeta(AppColors.neonGreen, LucideIcons.code, '提交需求代码，稳定产出但消耗精力'),
  'FIX_BUG': _CardMeta(AppColors.neonAmber, LucideIcons.bug, '修复遗留缺陷，快速补回KPI但大幅消耗精力'),
  'STUDY': _CardMeta(AppColors.neonCyan, LucideIcons.bookOpen, '提升面试竞争力，但占用工作时间增加怀疑'),
  'SLACK': _CardMeta(AppColors.neonMagenta, LucideIcons.coffee, '适当放松恢复精力，但容易被同事盯上'),
  'OVERTIME': _CardMeta(AppColors.neonAmber, LucideIcons.clock, '加班赶进度，挽回KPI但极度压榨精力'),
  'MENTOR': _CardMeta(AppColors.neonCyan, LucideIcons.users, '带领新人积累人脉，提升面试经验'),
  'REFACTOR': _CardMeta(AppColors.neonAmber, LucideIcons.puzzle, '优化旧代码结构，提升技术口碑'),
  'BLOG': _CardMeta(AppColors.neonCyan, LucideIcons.fileText, '撰写技术博客，提升行业影响力'),
  'TECH_TALK': _CardMeta(AppColors.neonCyan, LucideIcons.mic, '做技术分享，展示领导力但引人注目'),
  'BROWSE': _CardMeta(AppColors.neonMagenta, LucideIcons.globe, '刷知乎摸鱼，恢复精力但增加怀疑'),
  'ARCH_REDESIGN': _CardMeta(AppColors.neonAmber, LucideIcons.layers, '推动架构迁移，KPI暴增但要求高精力'),
  'ALLIANCE': _CardMeta(AppColors.neonMagenta, LucideIcons.users, '拉帮结派建立小团体，降低怀疑度'),
};

class _CardMeta {
  final Color color;
  final IconData icon;
  final String description;
  const _CardMeta(this.color, this.icon, this.description);
}

class _ActionCard extends ConsumerStatefulWidget {
  final ActionDef action;
  final dynamic state;

  const _ActionCard({required this.action, required this.state});

  @override
  ConsumerState<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends ConsumerState<_ActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isDisabled = widget.action.isBlockedBy(state.energy as int);
    final meta = _actionMeta[widget.action.id] ?? _CardMeta(AppColors.textMuted, LucideIcons.helpCircle, '');

    // Compute resolved deltas (buffs/debuffs/skills applied)
    final modifierId = state.dayModifier as String?;
    final modifier = modifierId != null
        ? GameData.modifiers.where((m) => m.id == modifierId).firstOrNull
        : null;
    final activeSCs = GameData.statusConditions
        .where((sc) => (state.activeStatuses as List<String>).contains(sc.id))
        .toList();
    final ownedSkills = GameData.skills
        .where((s) => (state.skills as List<String>).contains(s.id))
        .toList();
    final resolved = resolveActionEffects(
      action: widget.action,
      state: state,
      modifier: modifier,
      activeStatuses: activeSCs,
      skills: ownedSkills,
    );

    return AnimatedScale(
      scale: _isPressed && !isDisabled ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOutCubic,
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) {
          setState(() => _isPressed = true);
          HapticFeedback.lightImpact();
          AudioManager().playSfx('click');
        },
        onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
        onTap: isDisabled ? null : () {
          // Delay so press-release scale animation plays before phase switch
          final id = widget.action.id;
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) ref.read(gameProvider.notifier).selectAction(id);
          });
        },
        child: GlassPanel(
          borderRadius: 12,
          padding: const EdgeInsets.all(8),
          bgColor: isDisabled ? const Color(0xFF1E1E1E) : null,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(meta.icon, size: 11, color: isDisabled ? AppColors.textDim : meta.color),
              const SizedBox(width: 4),
              Expanded(child: Text(widget.action.label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                      color: isDisabled ? AppColors.textDim : meta.color, fontFamily: 'Share Tech Mono'))),
            ]),
            const SizedBox(height: 6),
            Text(meta.description,
                style: TextStyle(fontSize: 9, color: Colors.grey[400]!, height: 1.2),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const Spacer(),
            _StatPills(deltas: resolved.deltas),
            if (isDisabled) ...[
              const SizedBox(height: 4),
              Text('ENERGY LOW', style: TextStyle(fontSize: 9, color: AppColors.neonRed)),
            ],
          ]),
        ),
      ),
    );
  }
}

class _StatPills extends ConsumerWidget {
  final dynamic deltas;
  const _StatPills({required this.deltas});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final pills = <Widget>[];
    void add(String label, int value, Color valColor) {
      pills.add(Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontSize: 10, color: theme.colors.textMuted)),
        const SizedBox(width: 2),
        Text(value > 0 ? '+$value' : '$value',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: valColor)),
      ]));
    }
    final e = deltas.energy as int;
    final k = deltas.kpi as int;
    final i = deltas.interview as int;
    final s = deltas.suspicion as int;
    if (e != 0) {
      add('ENR', e, e > 0 ? AppColors.neonGreen : AppColors.neonRed);
    }
    if (k != 0) {
      add('KPI', k, k > 0 ? AppColors.neonGreen : AppColors.neonRed);
    }
    if (i != 0) {
      add('INT', i, i > 0 ? AppColors.neonCyan : AppColors.neonRed);
    }
    if (s != 0) {
      add('SUS', s, s > 0 ? AppColors.neonRed : AppColors.neonGreen);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colors.bgSurface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(mainAxisSize: MainAxisSize.min, children: pills.expand((w) => [
          w, const SizedBox(width: 8),
        ]).toList()..removeLast()),
      ),
    );
  }
}

// ============================================================
// Interruption
// ============================================================

class InterruptionContent extends ConsumerWidget {
  const InterruptionContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intrId = ref.watch(gameProvider.select((s) => s.interruption));
    final intr = intrId != null
        ? GameData.interruptions.where((i) => i.id == intrId).firstOrNull
        : null;
    if (intr == null) return const SizedBox.shrink();

    return Center(child: Padding(
      padding: const EdgeInsets.all(16),
      child: GlassPanel(
        borderRadius: 8,
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 380),
        border: Border.all(color: AppColors.neonAmber.withAlpha(100)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Icon(LucideIcons.alertTriangle, size: 11, color: AppColors.neonAmber),
            const SizedBox(width: 6),
            Text('INTERRUPTION', style: TextStyle(fontSize: 10, color: AppColors.neonAmber)),
          ]),
          const SizedBox(height: 10),
          Text(intr.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
              fontFamily: 'Share Tech Mono', color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(intr.description, style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.5)),
          const SizedBox(height: 12),
          _TapButton(
            onTap: () => ref.read(gameProvider.notifier).acknowledgeInterruption(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.neonAmber.withAlpha(80)),
                  borderRadius: BorderRadius.circular(3)),
              child: Text('[ 知道了 ]', style: TextStyle(fontSize: 10, color: AppColors.neonAmber)),
            ),
          ),
        ]),
      ),
    ));
  }
}

// ============================================================
// Event
// ============================================================

class EventContent extends ConsumerWidget {
  const EventContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventId = ref.watch(gameProvider.select((s) => s.currentEventId));
    final event = eventId != null
        ? GameData.events.where((e) => e.id == eventId).firstOrNull
        : null;
    if (event == null) return const SizedBox.shrink();

    final isHighRisk = event.highRisk;

    // QTE mini-game branch
    if (event.qteConfig != null) {
      final suspicion = ref.watch(gameProvider.select((s) => s.suspicion));
      return Center(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(8),
            child: GlassPanel(
              borderRadius: 8,
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(maxWidth: 420),
              border: Border.all(color: isHighRisk ? AppColors.neonRed.withAlpha(150) : AppColors.neonCyan.withAlpha(100)),
              boxShadow: isHighRisk ? [BoxShadow(color: AppColors.neonRed.withAlpha(30), blurRadius: 12)] : null,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                      Icon(isHighRisk ? LucideIcons.shieldAlert : LucideIcons.alertTriangle,
                          size: 10, color: isHighRisk ? AppColors.neonRed : AppColors.neonAmber),
                      const SizedBox(width: 4),
                      Expanded(child: Text(event.title,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                              fontFamily: 'Share Tech Mono', color: AppColors.textPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Text(event.id, style: TextStyle(fontSize: 8, color: AppColors.textMuted)),
                    ]),
                    const SizedBox(height: 4),
                    Text(event.description, style: TextStyle(fontSize: 9, color: AppColors.textMuted, height: 1.3),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    QteGame(
                      config: event.qteConfig!,
                      suspicion: suspicion,
                      highRisk: isHighRisk,
                      onComplete: (result) {
                        ref.read(gameProvider.notifier).resolveQteEvent(event.id, result);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: GlassPanel(
            borderRadius: 8,
            padding: const EdgeInsets.all(14),
            constraints: const BoxConstraints(maxWidth: 420),
            border: Border.all(color: isHighRisk ? AppColors.neonRed.withAlpha(150) : AppColors.neonCyan.withAlpha(100)),
            boxShadow: isHighRisk ? [BoxShadow(color: AppColors.neonRed.withAlpha(30), blurRadius: 12)] : null,
            child: Column(children: [
          Row(children: [
            Icon(isHighRisk ? LucideIcons.shieldAlert : LucideIcons.alertTriangle,
                size: 11, color: isHighRisk ? AppColors.neonRed : AppColors.neonAmber),
            const SizedBox(width: 6),
            Expanded(child: Text(isHighRisk ? 'HIGH-RISK EVENT' : 'EVENT',
                style: TextStyle(fontSize: 10, color: isHighRisk ? AppColors.neonRed : AppColors.neonAmber))),
            Text(event.id, style: TextStyle(fontSize: 8, color: AppColors.textMuted)),
          ]),
          const SizedBox(height: 10),
          Text(event.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
              fontFamily: 'Share Tech Mono', color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(event.description, style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.5)),
          const SizedBox(height: 12),
          _EventOption(option: event.optionA, index: 0),
          const SizedBox(height: 8),
          _EventOption(option: event.optionB, index: 1),
        ]),
              ),
            ),
          ),
      );
    }
  }

class _EventOption extends ConsumerStatefulWidget {
  final EventOption option;
  final int index;
  const _EventOption({required this.option, required this.index});

  @override
  ConsumerState<_EventOption> createState() => _EventOptionState();
}

class _EventOptionState extends ConsumerState<_EventOption> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
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
        onTap: () {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) ref.read(gameProvider.notifier).selectEventOption(widget.index);
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderDim),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white.withValues(alpha: 0.05),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.option.text, style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            _OptionEffectRow(option: widget.option),
          ]),
        ),
      ),
    );
  }
}

class _OptionEffectRow extends StatelessWidget {
  final EventOption option;
  const _OptionEffectRow({required this.option});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 2, children: option.effects.map((e) {
      final label = switch (e.type) { 'ENERGY' => 'ENR', 'KPI' => 'KPI', 'INTERVIEW' => 'INT', _ => 'SUS' };
      final sign = e.value > 0 ? '+' : '';
      final isNeg = e.type == 'SUSPICION' ? e.value > 0 : e.value < 0;
      return Text('$label$sign${e.value}',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
              color: isNeg ? AppColors.neonRed : AppColors.neonGreen));
    }).toList());
  }
}

// ============================================================
// Settlement
// ============================================================

class SettlementContent extends StatelessWidget {
  const SettlementContent({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('PROCESSING...', style: TextStyle(fontSize: 14, fontFamily: 'Share Tech Mono', color: AppColors.neonCyan)),
        const SizedBox(height: 12),
        const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(
            color: AppColors.neonGreen, strokeWidth: 2)),
      ])),
    );
  }
}

class _PhaseLabel extends StatelessWidget {
  final String text;
  const _PhaseLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text, style: TextStyle(fontSize: 13, color: AppColors.neonCyan)));
  }
}
