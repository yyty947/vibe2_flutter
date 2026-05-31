import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../state/providers.dart';
import '../state/theme_provider.dart';
import '../data/game_data.dart';
import '../models/status_condition.dart' show StatusCondition;
import '../theme/colors.dart';
import 'animated_number.dart';

// ============================================================
// Left panel: Day counter + 30-day timeline (7-day groups)
// ============================================================

class LeftDatePanel extends ConsumerWidget {
  const LeftDatePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(gameProvider.select((s) => s.day));
    final theme = ref.watch(themeProvider);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: theme.colors.bgPanel,
        border: Border(right: BorderSide(color: theme.colors.dividerColor)),
      ),
      child: GestureDetector(
        onTap: () => _showLegend(context),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        // Big day number
        Container(
          width: 28, height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: theme.colors.neonGreen.withAlpha(20), shape: BoxShape.circle),
          child: Text('$day', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
              fontFamily: 'Share Tech Mono', color: theme.colors.neonGreen)),
        ),
        const SizedBox(height: 2),
        Text('/30', style: TextStyle(fontSize: 8, color: theme.colors.textMuted)),
        const SizedBox(height: 6),

        // Timeline: 8 rows × 4 dots each
        ...List.generate(8, (row) {
          final start = row * 4 + 1;
          final end = (start + 3).clamp(1, 30);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children:
              List.generate(end - start + 1, (i) {
                final d = start + i;
                final isPast = d < day;
                final isCurrent = d == day;

                // Special day markers
                const weekReviewDays = {7, 14, 21};
                const qteDays = {5, 10, 15, 20, 25};
                final isWeekReview = weekReviewDays.contains(d);
                final isQte = qteDays.contains(d);
                final isConflict = isWeekReview && isQte;

                Color dotColor;
                double alpha;
                if (isCurrent) {
                  alpha = 1.0;
                } else if (isPast) {
                  alpha = 0.7;
                } else {
                  alpha = 0.4;
                }
                if (isConflict) {
                  dotColor = AppColors.neonRed;
                } else if (isWeekReview) {
                  dotColor = AppColors.neonAmber;
                } else if (isQte) {
                  dotColor = AppColors.neonCyan;
                } else if (isCurrent) {
                  dotColor = theme.colors.neonGreen;
                } else if (isPast) {
                  dotColor = theme.colors.neonGreen;
                } else {
                  dotColor = theme.colors.barBg;
                  alpha = 1.0;
                }

                return Container(
                  width: 10, height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: dotColor.withAlpha((alpha * 255).round()),
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              }),
            ),
          );
        }),
      ]),
      ),
    );
  }
}

// ============================================================
// Right panel: 4 stat bars + Buffs + Phase
// ============================================================

void _showLegend(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.bgPanel,
      title: const Text('日期标记', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _legendRow(AppColors.neonGreen, '当前天数'),
        const SizedBox(height: 6),
        _legendRow(AppColors.neonCyan, 'CSS居中考核'),
        const SizedBox(height: 6),
        _legendRow(AppColors.neonAmber, '周度复盘结算'),
        const SizedBox(height: 6),
        _legendRow(AppColors.neonRed, '考核+复盘同日'),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('知道了', style: TextStyle(fontSize: 12, color: AppColors.neonGreen)),
        ),
      ],
    ),
  );
}

Widget _legendRow(Color color, String label) {
  return Row(children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
  ]);
}

class RightStatsPanel extends ConsumerStatefulWidget {
  const RightStatsPanel({super.key});

  @override
  ConsumerState<RightStatsPanel> createState() => _RightStatsPanelState();
}

class _RightStatsPanelState extends ConsumerState<RightStatsPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanCtrl;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat();
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final theme = ref.watch(themeProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colors.bgPanel,
        border: Border(left: BorderSide(color: theme.colors.dividerColor)),
      ),
      child: Stack(children: [
        // Main content
        Column(children: [
        // Fixed top: 4 stats
        _RightStat(label: 'ENERGY', value: state.energy,
            color: theme.colors.neonGreen, inverted: false, icon: LucideIcons.zap),
        const SizedBox(height: 6),
        _RightStat(label: 'KPI', value: state.kpi,
            color: theme.colors.neonCyan, inverted: false, icon: LucideIcons.trendingUp),
        const SizedBox(height: 6),
        _RightStat(label: 'INTERVIEW', value: state.interview,
            color: theme.colors.neonAmber, inverted: false, icon: LucideIcons.target),
        const SizedBox(height: 6),
        _RightStat(label: 'SUSPICION', value: state.suspicion,
            color: theme.colors.neonRed, inverted: true, icon: LucideIcons.eye),
        const SizedBox(height: 8),
        Container(height: 1, color: AppColors.borderDim),
        const SizedBox(height: 4),
        // Scrollable middle: skills + buffs
        Expanded(child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Skill points
            Row(children: [
              Icon(LucideIcons.coins, size: 9, color: state.skillPoints > 0 ? AppColors.neonAmber : theme.colors.textMuted),
              const SizedBox(width: 3),
              Text('${state.skillPoints}pt', style: TextStyle(fontSize: 8,
                  color: state.skillPoints > 0 ? AppColors.neonAmber : theme.colors.textMuted)),
              const Spacer(),
              Text('成长点', style: TextStyle(fontSize: 7, color: theme.colors.textMuted)),
            ]),
            if (state.skills.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(spacing: 3, runSpacing: 3, children: state.skills.map((id) {
                final sk = GameData.skills.where((s) => s.id == id).firstOrNull;
                if (sk == null) return const SizedBox.shrink();
                final iconData = skillIcons[sk.icon] ?? LucideIcons.star;
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) => Transform.scale(scale: value, child: child),
                  child: GestureDetector(
                    onTap: () => showInfoPopup(context,
                      title: sk.name, effect: formatSkillEffects(sk.effects), flavor: sk.description,
                      color: theme.colors.neonGreen),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colors.neonGreen.withAlpha(15),
                        border: Border.all(color: theme.colors.neonGreen.withAlpha(80)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(iconData, size: 12, color: theme.colors.neonGreen),
                        const SizedBox(width: 2),
                        Text(sk.name, style: TextStyle(fontSize: 9, color: theme.colors.neonGreen)),
                      ]),
                    ),
                  ),
                );
              }).toList()),
            ],
            const SizedBox(height: 4),
            Container(height: 1, color: AppColors.borderDim),
            const SizedBox(height: 4),
            // BuffBar
            const _RightBuffBar(),
          ]),
        )),
        // Phase label
        Text(state.phase.label, style: TextStyle(fontSize: 8, color: theme.colors.textMuted)),
      ]),
        // Scanline overlay — fade in at top, fade out at bottom, 500ms pause
        AnimatedBuilder(
          animation: _scanCtrl,
          builder: (context, _) {
            final t = _scanCtrl.value;
            // Position: always moving top→bottom, then invisible reset
            final pos = t < 0.85 ? -1.0 + 2.0 * t / 0.85 : -1.0;
            // Opacity: fade in while moving at top, fade out while moving near bottom
            final opacity = t < 0.12 ? t / 0.12     // fade in during first ~12% of travel
                : t < 0.73 ? 1.0                     // full visibility
                : t < 0.85 ? 1.0 - (t - 0.73) / 0.12 // fade out during last ~12%
                : 0.0;                               // invisible reset
            return Opacity(
              opacity: opacity,
              child: Align(
                alignment: Alignment(0, pos),
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glow fade above the beam
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          theme.colors.neonGreen.withAlpha(8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // The beam itself with horizontal+cross fade
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          theme.colors.neonGreen.withAlpha(140),
                          theme.colors.neonGreen,
                          theme.colors.neonGreen.withAlpha(140),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.15, 0.5, 0.85, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colors.neonGreen.withAlpha(50),
                          blurRadius: 3, spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  // Glow fade below the beam
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          theme.colors.neonGreen.withAlpha(8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          },
        ),
      ]),
    );
  }
}

class _RightStat extends ConsumerStatefulWidget {
  final String label;
  final int value;
  final Color color;
  final bool inverted;
  final IconData icon;

  const _RightStat({required this.label, required this.value, required this.color,
    required this.inverted, required this.icon});

  @override
  ConsumerState<_RightStat> createState() => _RightStatState();
}

class _RightStatState extends ConsumerState<_RightStat> with SingleTickerProviderStateMixin {
  late AnimationController _breathCtrl;
  int _prevValue = -1;
  int _deltaKey = 0;

  // INTERVIEW never gets threshold effects
  bool get _noEffect => widget.label == 'INTERVIEW';

  bool get _isWarning {
    if (_noEffect) return false;
    if (widget.inverted) return widget.value >= 70 && widget.value < 85;
    return widget.value <= 20 && widget.value > 10;
  }

  bool get _isDanger {
    if (_noEffect) return false;
    if (widget.inverted) return widget.value >= 85;
    return widget.value <= 10;
  }

  Color get _effectiveColor {
    // INTERVIEW always yellow, SUSPICION always red — never change base color
    if (_noEffect || widget.inverted) return widget.color;
    // ENERGY / KPI threshold colors
    if (_isDanger) return AppColors.neonRed;
    if (_isWarning) return AppColors.neonAmber;
    return widget.color;
  }

  int get _delta => widget.value - _prevValue;

  bool get _deltaIsGood {
    if (widget.inverted) return _delta < 0;
    return _delta > 0;
  }

  @override
  void initState() {
    super.initState();
    _prevValue = widget.value;
    _breathCtrl = AnimationController(vsync: this);
    _syncBreath();
  }

  @override
  void didUpdateWidget(_RightStat old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _prevValue = old.value;
      _deltaKey++;
    }
    _syncBreath();
  }

  void _syncBreath() {
    final needBreath = _isWarning || _isDanger;
    if (needBreath) {
      final dur = Duration(milliseconds: _isDanger ? 700 : 1500);
      if (_breathCtrl.duration != dur || !_breathCtrl.isAnimating) {
        _breathCtrl.duration = dur;
        _breathCtrl.repeat(reverse: true);
      }
    } else {
      _breathCtrl.stop();
      _breathCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final c = _effectiveColor;
    final barBg = theme.colors.barBg;
    final showGlow = _isDanger;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // --- Icon + Label + Value row ---
      AnimatedBuilder(
        animation: _breathCtrl,
        builder: (context, child) {
          final breatheOn = _isWarning || _isDanger;
          final opacity = breatheOn ? 0.45 + 0.55 * _breathCtrl.value : 1.0;
          return Opacity(
            opacity: opacity,
            child: Row(children: [
              Icon(widget.icon, size: 9, color: c),
              const SizedBox(width: 4),
              Text(widget.label, style: TextStyle(fontSize: 8, color: c)),
              const Spacer(),
              // Value + floating delta overlay
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedNumber(value: widget.value, inverted: widget.inverted, baseColor: c),
                  if (_delta != 0)
                    Positioned(
                      right: 0, top: -14,
                      child: _FloatingDeltaText(
                        key: ValueKey(_deltaKey),
                        delta: _delta,
                        isGood: _deltaIsGood,
                      ),
                    ),
                ],
              ),
            ]),
          );
        },
      ),
      const SizedBox(height: 2),
      // --- Progress bar ---
      TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: _prevValue.clamp(0, 100) / 100.0, end: widget.value.clamp(0, 100) / 100.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, barVal, _) {
          return AnimatedBuilder(
            animation: _breathCtrl,
            builder: (context, child) {
              final breathe = _breathCtrl.value;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: showGlow
                      ? [BoxShadow(
                          color: AppColors.neonRed.withValues(alpha: 0.25 + 0.2 * breathe),
                          blurRadius: 4 + 5 * breathe,
                          spreadRadius: 1,
                        )]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(1),
                  child: LinearProgressIndicator(
                    value: barVal,
                    minHeight: 5,
                    backgroundColor: barBg,
                    valueColor: AlwaysStoppedAnimation(c),
                  ),
                ),
              );
            },
          );
        },
      ),
    ]);
  }
}

// ============================================================
// Floating delta text — slides up and fades out on stat change
// ============================================================

class _FloatingDeltaText extends StatefulWidget {
  final int delta;
  final bool isGood;
  const _FloatingDeltaText({super.key, required this.delta, required this.isGood});

  @override
  State<_FloatingDeltaText> createState() => _FloatingDeltaTextState();
}

class _FloatingDeltaTextState extends State<_FloatingDeltaText> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _opacity = Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1.0)));
    _slide = Tween(begin: Offset.zero, end: const Offset(0, -1.6)).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sign = widget.delta > 0 ? '+' : '';
    final color = widget.isGood ? AppColors.neonGreen : AppColors.neonRed;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return SlideTransition(
          position: _slide,
          child: Opacity(
            opacity: _opacity.value,
            child: Text(
              '$sign${widget.delta}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// Buff bar (right panel)
// ============================================================

// ============================================================
// Shared info popup — reused by buff chips and skill chips
// ============================================================

void showInfoPopup(BuildContext context, {
  required String title,
  required String effect,
  required String flavor,
  required Color color,
}) {
  showDialog(context: context, builder: (_) => AlertDialog(
    backgroundColor: AppColors.bgPanel,
    title: Text(title, style: TextStyle(fontSize: 16, color: color)),
    content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(effect, style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      Text(flavor, style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context),
          child: Text('OK', style: TextStyle(fontSize: 13, color: AppColors.neonGreen))),
    ],
  ));
}

String formatSkillEffects(Map<String, double> effects) {
  final parts = <String>[];
  for (final e in effects.entries) {
    final pct = (e.value * 100).round();
    final sign = pct >= 0 ? '+' : '';
    switch (e.key) {
      case 'energyCostMultiplier': parts.add('精力消耗 $sign$pct%');
      case 'kpiGainMultiplier': parts.add('KPI收益 $sign$pct%');
      case 'suspicionGainMultiplier': parts.add('怀疑度增长 $sign$pct%');
      case 'interviewGainMultiplier': parts.add('面试收益 $sign$pct%');
      case 'allGainMultiplier': parts.add('所有收益 $sign$pct%');
      default: parts.add('${e.key} $sign$pct%');
    }
  }
  return parts.isEmpty ? '无被动效果' : parts.join(' · ');
}

final skillIcons = <String, IconData>{
  'BatteryMedium': LucideIcons.batteryMedium, 'BatteryFull': LucideIcons.batteryFull,
  'BatteryCharging': LucideIcons.batteryCharging, 'Code2': LucideIcons.code2,
  'TerminalSquare': LucideIcons.terminalSquare, 'Cpu': LucideIcons.cpu,
  'MessageCircle': LucideIcons.messageCircle, 'Users': LucideIcons.users,
  'HeartHandshake': LucideIcons.heartHandshake, 'BookOpen': LucideIcons.bookOpen,
  'BookMarked': LucideIcons.bookMarked, 'Rocket': LucideIcons.rocket,
};

// ============================================================
// Buff bar (right panel)
// ============================================================

class _RightBuffBar extends ConsumerWidget {
  const _RightBuffBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeStatuses = ref.watch(gameProvider.select((s) => s.activeStatuses));
    if (activeStatuses.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 3, runSpacing: 3, children: [
      for (final statusId in activeStatuses)
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.elasticOut,
          builder: (context, value, child) => Transform.scale(scale: value, child: child),
          child: _BuffChip(statusId: statusId),
        ),
    ]);
  }
}

class _BuffChip extends ConsumerWidget {
  final String statusId;
  const _BuffChip({required this.statusId});

  StatusCondition? get cond => GameData.statusConditions.where((c) => c.id == statusId).firstOrNull;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cond = this.cond;

    if (cond == null) return const SizedBox.shrink();

    final theme = ref.watch(themeProvider);
    final isBuff = cond.isBuff;
    final c = isBuff ? theme.colors.neonGreen : theme.colors.neonRed;

    final iconData = buffIcon(cond.id);

    return GestureDetector(
      onTap: () => showInfoPopup(context,
        title: cond.name, effect: cond.tooltip.effect, flavor: cond.tooltip.flavor, color: c),
      child: Row(children: [
        if (iconData != null) Icon(iconData, size: 14, color: c),
        const SizedBox(width: 4),
        Flexible(child: Text(cond.name, style: TextStyle(fontSize: 10, color: c), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

IconData? buffIcon(String id) {
  switch (id) {
    case 'ENERGIZED': return LucideIcons.zap;
    case 'BURNOUT': return LucideIcons.batteryWarning;
    case 'TRUSTED': return LucideIcons.shieldCheck;
    case 'UNDER_SURVEIL': return LucideIcons.shieldAlert;
    case 'CORE_MEMBER': return LucideIcons.star;
    case 'TRUST_CRISIS': return LucideIcons.eyeOff;
    case 'IN_THE_ZONE': return LucideIcons.crown;
    case 'COLLAPSE': return LucideIcons.heartCrack;
    default: return null;
  }
}
