import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/colors.dart';

/// Full-screen tutorial overlay explaining game mechanics.
class TutorialScreen extends StatelessWidget {
  final VoidCallback onBack;
  const TutorialScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgDeep.withAlpha(245),
      child: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF111116),
              border: Border(bottom: BorderSide(color: Color(0xFF2A2A35))),
            ),
            child: Row(children: [
              Icon(LucideIcons.bookOpen, size: 14, color: AppColors.neonAmber),
              const SizedBox(width: 8),
              Text('玩法介绍',
                  style: TextStyle(fontFamily: 'Share Tech Mono', fontSize: 14,
                      fontWeight: FontWeight.bold, color: AppColors.neonGreen)),
              const SizedBox(width: 10),
              Text('GAMEPLAY MANUAL',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              const Spacer(),
              _ReturnButton(onTap: onBack),
            ]),
          ),
          // Content
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Section(
                icon: LucideIcons.zap, color: AppColors.neonGreen,
                title: '核心属性',
                body: '你的生存状态由四项属性决定：\n\n'
                    'ENERGY（精力）— 执行任何行动都需要消耗精力。归零将触发死亡结局。\n'
                    'KPI（绩效）— 你的工作产出。过低会被裁员，过高则引人注目。\n'
                    'INTERVIEW（面试度）— 为跳槽做的准备。达到 90 可触发金蝉脱壳结局。\n'
                    'SUSPICION（怀疑度）— 老板和HR对你的警惕程度。过高会触发严苛事件。',
              ),
              _Section(
                icon: LucideIcons.calendar, color: AppColors.neonCyan,
                title: '每日流程（Day 1 — 30）',
                body: '每个游戏日分为以下相位：\n\n'
                    'OPENING — 当天的开场剧情\n'
                    'MORNING — 上午行动（4选1）\n'
                    'AFTERNOON — 下午行动（4选1）\n'
                    'EVENT — 随机职场事件（二选一）\n'
                    'SETTLEMENT — 日终结算，精力 -5，检查结局\n\n'
                    'Day 7 / 14 / 21 会弹出周度复盘，可用成长点学习技能。\n'
                    'Day 30 结算时必定触发最终结局。',
              ),
              _Section(
                icon: LucideIcons.grid, color: AppColors.neonAmber,
                title: '行动选择（12选4动态池）',
                body: '每次 Morning 和 Afternoon 行动阶段，从 12 种行动中随机抽取 4 种供你选择。\n\n'
                    '写业务代码 — 稳定产出，降低怀疑\n'
                    '修屎山Bug — 大幅提升KPI，消耗精力\n'
                    '偷偷刷八股文 — 提升面试度，增加怀疑\n'
                    '带薪拉屎 — 恢复精力\n'
                    '帮助新人 / 架构重构 / 写技术博客 / 技术分享\n'
                    '刷知乎摸鱼 / 加班 / 底层架构迁移 / 拉帮结派\n\n'
                    '部分行动有精力或技能前置条件。周末有限定行动。',
              ),
              _Section(
                icon: LucideIcons.shield, color: AppColors.neonMagenta,
                title: 'Buff / Debuff 系统',
                body: '根据你的属性值，会自动激活增益（Buff）或减益（Debuff）状态：\n\n'
                    'ENERGIZED — 精力 ≥ 80：精力消耗 -20%\n'
                    'TRUSTED — 怀疑 ≤ 25：KPI收益 +20%，怀疑增长 -30%\n'
                    'CORE_MEMBER — KPI ≥ 75：KPI收益 +25%\n'
                    'IN_THE_ZONE — KPI≥65 & 精力≥60 & 怀疑≤35：所有收益 +15%\n\n'
                    'BURNOUT — 精力 ≤ 25：KPI收益 -30%，精力消耗 +30%\n'
                    'TRUST_CRISIS — 怀疑 ≥ 65：KPI收益 -25%\n'
                    'UNDER_SURVEIL — 怀疑 ≥ 85：面试收益 -30%，怀疑增长 +30%\n'
                    'COLLAPSE — 精力 ≤ 15：所有收益 -20%，精力消耗 +50%\n\n'
                    '同一领域（精/KPI/疑）只激活最高优先级的 Buff 和 Debuff 各一个。',
              ),
              _Section(
                icon: LucideIcons.star, color: AppColors.neonCyan,
                title: '技能树（4分支 × 3层）',
                body: 'Day 7 / 14 / 21 结算时获得成长点（点数 = 基础值 + KPI ÷ 系数）。\n\n'
                    '四个分支：\n'
                    '精力管理（绿色）— 降低精力消耗\n'
                    '代码效率（青色）— 提升KPI收益\n'
                    '社交技巧（琥珀）— 降低怀疑度增长\n'
                    '面试精进（品红）— 提升面试收益\n\n'
                    '每层技能需要前置技能。高级技能解锁专属行动。\n'
                    '已学技能可在复盘面板中二次点击撤销（退成长点）。',
              ),
              _Section(
                icon: LucideIcons.repeat, color: AppColors.neonRed,
                title: '连选惩罚（Streak Penalty）',
                body: '如果你连续选择同一个行动，收益将大幅递减：\n\n'
                    '第 2 次连续 — 终端警告，收益开始衰减\n'
                    '第 3 次及以上 — 严重衰减，终端打印惩罚日志\n\n'
                    '建议每轮行动选择不同类型的行动，避免单一策略。',
              ),
              _Section(
                icon: LucideIcons.flag, color: AppColors.neonAmber,
                title: '五种结局',
                body: 'BE_DEATH — 精力归零，ICU抢救无效\n'
                    'BE_FIRED — 绩效垫底，被保安请出大楼\n'
                    'GE_OFFER — 面试度 ≥ 90，跳槽成功\n'
                    'NE_PEACE — 表现正常，拿到 N+1 体面离开\n'
                    'HE_KING — 全属性达标，活到最后（但你真的赢了吗？）\n\n'
                    'SUSPICION 过高（≥ 70）会触发压力事件，进一步影响结局走向。',
              ),
              _Section(
                icon: LucideIcons.lightbulb, color: AppColors.neonGreen,
                title: '玩家小贴士',
                body: '· 前期（Day 1-10）优先降低怀疑度，获取 TRUSTED buff\n'
                    '· 中期（Day 11-20）平衡精力和KPI，适当刷面试题\n'
                    '· 后期（Day 21-30）冲刺目标结局，注意连选惩罚\n'
                    '· 不要忽视周末限定行动（写技术博客）\n'
                    '· 精力低于 20 时优先恢复，避免触发危险阈值\n'
                    '· 善用技能树的撤销功能，灵活调整策略',
              ),
              const SizedBox(height: 32),
            ]),
          )),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _Section({
    required this.icon, required this.color,
    required this.title, required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withAlpha(12),
            border: Border(left: BorderSide(color: color, width: 2)),
          ),
          child: Row(children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(fontFamily: 'Share Tech Mono', fontSize: 14,
                    fontWeight: FontWeight.bold, color: color)),
          ]),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(body,
              style: TextStyle(fontSize: 12, color: AppColors.textPrimary.withAlpha(210), height: 1.7)),
        ),
      ]),
    );
  }
}

class _ReturnButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ReturnButton({required this.onTap});

  @override
  State<_ReturnButton> createState() => _ReturnButtonState();
}

class _ReturnButtonState extends State<_ReturnButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.93 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOutCubic,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _pressed = true);
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neonGreen.withAlpha(80)),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text('[ 返回 ]',
              style: TextStyle(fontSize: 11, fontFamily: 'Fira Code', color: AppColors.neonGreen)),
        ),
      ),
    );
  }
}
