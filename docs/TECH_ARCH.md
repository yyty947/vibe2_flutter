> **摘要 (Abstract)**: 本文档定义了《前端生死劫》Flutter 版的技术实现标准与状态流转逻辑。核心采用 Flutter + Dart + Riverpod 的组合，实现纯客户端驱动的"状态机游戏"。文档锁定了完整的状态模型（v1.3.0，含技能系统、状态条件、连选惩罚等扩展）、游戏循环状态机（含打断/压力事件/周度复盘流程）、结局判定算法、事件抽取算法及存档架构，确保 AI 在生成功能逻辑时遵循统一的单向数据流与边界检查规则。最后更新：2026-05-03（Flutter 迁移）。


## 1. 技术栈选型 (Technology Stack)

- **框架**: Flutter (Dart)
- **UI**: Widget tree (`StatelessWidget` / `StatefulWidget` + `ConsumerWidget`)
- **状态管理**: Riverpod (`Notifier<GameState>` — 轻量、支持外部逻辑抽离，适合游戏状态机)
- **持久化**: `SharedPreferences` (key: `frontend-survival-save`)
- **图标库**: `lucide_icons` (`LucideIcons.*`)
- **动画**: Flutter 内置 (`AnimationController` / `Tween` / `AnimatedBuilder` / `TweenAnimationBuilder`)
- **音频**: `audioplayers` (`AudioPlayer`，懒加载，单例管理)
- **测试**: `flutter test` (package:test + package:flutter_test，单元 + 集成 248 cases)


## 2. 核心状态模型 (Core State Schema)

状态必须集中管理，禁止在 Widget 层级随意定义全局变量。

### 2.1 完整类型定义

```dart
/// 终端日志条目
class LogEntry {
  final int day;
  final LogType type;  // INFO | WARNING | ALERT | COMMIT | BUGFIX | STUDY | SLACK
  final String message;
}

/// 行动历史统计
class ActionStats {
  final int writeCode;
  final int fixBug;
  final int studyInterview;
  final int slack;
}

/// 游戏主状态 — GameNotifier 的唯一数据源
class GameState {
  // 基础资源 [0, 100]，所有更新必须经过钳位
  final int energy;       // 精力
  final int kpi;          // 绩效
  final int interview;    // 面试准备度
  final int suspicion;    // 老板怀疑度

  // 时间进度
  final int day;          // 当前天数 [1, 30]
  final GamePhase phase;  // 当前阶段（7 个枚举值）

  // 历史记录
  final List<String> eventHistory;   // 已触发事件 ID 列表
  final List<LogEntry> logs;         // 终端日志队列

  // 存档元数据
  final String version;              // "1.3.0"
  final int savedAt;                 // DateTime.now().millisecondsSinceEpoch
  final ActionStats actionStats;     // 玩家行动历史统计

  // 运行时状态
  final String? currentEventId;      // 当前正在显示的事件 ID
  final String? ending;              // 已触发的结局类型 label

  // Patch-F01/F02: 日间修饰符 & 打断 & 怀疑度压力
  final String? dayModifier;         // 当日修饰符 ID
  final String? interruption;        // 打断事件 ID
  final String? suspicionPressure;   // 怀疑度高压晨间事件 ID

  // Patch-F03: Buff/Debuff 状态条件
  final List<String> activeStatuses; // 当前激活的状态条件 ID 列表

  // Patch-F04: 连选惩罚
  final String streakActionId;       // 当前连续选择的行动 ID
  final int streakCount;             // 连续次数

  // Patch-F05: 技能系统
  final int skillPoints;             // 成长点余额
  final List<String> skills;         // 已习得技能 ID 列表
  final bool showWeekReview;         // 是否显示周度复盘弹窗

  // 运行时 UI 标志
  final bool skipAllTyping;

  // Patch-F16: 开场视频（瞬态 UI 状态，不序列化）
  final bool showIntroVideo;
}
```

### 2.2 初始值常量

```dart
static const GameState initial = GameState(
  energy: 75,
  kpi: 50,
  interview: 10,
  suspicion: 20,
  day: 1,
  phase: GamePhase.title,
);
```

### 2.3 数值钳位工具

```dart
int clamp(int val, {int min = 0, int max = 100}) {
  if (val < min) return min;
  if (val > max) return max;
  return val;
}
```

所有对 `energy` / `kpi` / `interview` / `suspicion` 的写入操作，必须通过 `clamp()` 包裹，禁止绕过。定义于 `lib/utils/clamp.dart`。

### 2.4 copyWith 与可空字段 (Sentinel 模式)

`GameState.copyWith()` 对可空字段（`currentEventId`, `ending`, `dayModifier`, `interruption`, `suspicionPressure`）使用 **sentinel 模式**：参数类型为 `Object?`，默认值为 `_sentinel`，通过 `identical()` 区分"未传参"和"显式传 null"。

```dart
GameState copyWith({
  ...
  Object? currentEventId = _sentinel,
  ...
}) {
  return GameState(
    currentEventId: identical(currentEventId, _sentinel)
        ? this.currentEventId : currentEventId as String?,
    ...
  );
}
```


## 3. 游戏循环状态机 (Game Loop State Machine)

### 3.1 相位枚举

```dart
enum GamePhase {
  title('TITLE'),
  opening('OPENING'),
  morning('MORNING'),
  afternoon('AFTERNOON'),
  event('EVENT'),
  settlement('SETTLEMENT'),
  ending('ENDING');
}
```

### 3.2 全生命周期状态流转图

```
TITLE ──[startNewGame / continueGameFrom]──→ OPENING ──[skipOpening]──→ MORNING
  │                                              │
  │                                              │[selectAction]
  │                                              ↓
  │                                         AFTERNOON
  │                                              │
  │                                              │[selectAction]
  │                                              ↓
  │                                            EVENT
  │                                              │
  │                                              │[triggerEvent / selectEventOption]
  │                                              ↓
  │                                         SETTLEMENT
  │                                         │         │
  │                          [触发结局]     │         │[未触发结局]
  │                                        ↓         ↓
  │                                      ENDING    day++ → OPENING
  │                                        │
  └────────────[restart]───────────────────┘
```

### 3.3 相位职责与转换规则

| 当前相位 | 职责 | 转出条件 | 目标相位 |
|---------|------|---------|---------|
| **TITLE** | 渲染标题画面。检测存档决定是否显示"继续游戏"按钮 | `startNewGame()` | OPENING (初始化, day=1) |
| | | `continueGameFrom(saved)` | OPENING (恢复存档) |
| **OPENING** | 显示开场白（打字机）。分配 modifier + 检查压力事件 | `skipOpening()` | MORNING |
| **MORNING** | 行动选择（dynamic pool 4选1）+ 25% 打断判定 | `selectAction(id)` | AFTERNOON / 打断弹窗 |
| **AFTERNOON** | 同 MORNING（无打断） | `selectAction(id)` | EVENT |
| **EVENT** | `triggerEvent()` 执行事件抽取 → 弹窗或跳过 | `selectEventOption(i)` / 空抽 | SETTLEMENT |
| **SETTLEMENT** | ① 精力 -5 ② checkDailyEnding ③ day=30? checkFinalEnding ④ 结局或 day++ | 触发结局 | ENDING |
| | | 未触发结局 | OPENING (day+1) |
| **ENDING** | 渲染结局画面。演出完成后清除存档。提供"重新开始" | `restart()` | TITLE |

**关键约束**：
- OPENING → MORNING 是自动的（`skipOpening()`），不需要玩家额外操作。
- SETTLEMENT 逻辑必须在 `runSettlement()` 中同步完成，禁止拆分为多帧。
- 进入 ENDING 后由 `EndingScreen` 在 glitch/reveal 动画完成时清除存档。

**相位验证**：`lib/logic/game_loop.dart` — `isValidTransition(from, to)` + `LEGAL_TRANSITIONS` map。所有 GameNotifier 相位转换处均有 `assert(isValidTransition(...))`。

**自动相位推进**：`lib/screens/game_screen.dart` → `_GameLayoutState.build()` 中 `_tryAdvance(s)` — 每次 build 时检查当前相位，通过 `addPostFrameCallback` 触发对应动作（`triggerEvent()` / `runSettlement()` / `assignDayModifier()`）。**注意**: 旧版使用 `didChangeDependencies` + `ref.listenManual` 方式，现已简化为 build 内直接调用。


## 4. 结局判定算法 (Ending Resolution)

### 4.1 日结清算检查（Day 1-30 每日执行）

```dart
String? checkDailyEnding(int energy, int kpi, int interview, int suspicion) {
  // 检查 1：精力耗尽
  if (energy <= 0) return EndingType.beDeath.label;
  // 检查 2：绩效垫底
  if (kpi <= 0) return EndingType.beFired.label;
  // 检查 3：提前跳槽（interview ≥ 80 且未被盯上 — Patch-F02）
  if (interview >= 80 && suspicion < 85) return EndingType.geOffer.label;
  return null;
}
```

### 4.2 最终审判（仅 Day 30，且 checkDailyEnding 返回 null 后）

```dart
String checkFinalEnding(int energy, int kpi, int interview, int suspicion) {
  // 优先级 1：内卷之王
  if (kpi >= 80 && suspicion < 30 && energy >= 20) return EndingType.heKing.label;
  // 优先级 2：成功跳槽（怀疑度门槛 — Patch-F02）
  if (interview >= 60 && suspicion < 70) return EndingType.geOffer.label;
  // 优先级 3：和平分手
  if (kpi >= 30 && suspicion < 70 && energy > 0) return EndingType.nePeace.label;
  // 优先级 4：绩效垫底（兜底 — Patch-011）
  return EndingType.beFired.label;
}
```

实现于 `lib/logic/endings.dart`。


## 5. 事件抽取算法 (Event Sampling)

```dart
GameEvent? sampleEvent(GameState state, List<GameEvent> allEvents) {
  // Step 1: 空事件概率（suspicion ≥ 80 → 5%, else 10%）
  final nullChance = state.suspicion >= 80 ? 0.05 : 0.1;
  if (random.nextDouble() < nullChance) return null;

  // Step 2: 过滤满足前置条件的事件（条件检查 + 周末过滤高危）
  final eligible = allEvents.where((e) =>
    isEventConditionMet(e.condition, state) &&
    !(e.highRisk && isWeekend(state.day))
  ).toList();
  if (eligible.isEmpty) return null;

  // Step 3: 权重调整（50% 衰减已触发 + 高危怀疑度倍率提升）
  // Step 4: 加权随机抽取
}
```

实现于 `lib/logic/events.dart`。


## 6. 行动系统 (Action System)

### 6.1 动态行动池

`lib/logic/action_pool.dart` → `sampleActionPool(state, allActions, activeSkills)`：
- 保证 ≥2 个核心行动
- 保证 ≥1 个休息行动（energy > 0）+ ≥1 个工作行动（energy < 0）
- 条件行动按状态/day/技能筛选

### 6.2 行动效果修正链（6 步）

`lib/logic/action_resolver.dart` → `resolveActionEffects()`：

1. **连选惩罚** (`_StreakEntry` 表): 同行动连续 2/3/4+ 次逐步衰减
2. **即时抓包** (`_checkSpotCheck()`): suspicion ≥ 70 时 STUDY/SLACK 概率触发额外惩罚
3. **日间修饰符**: `DayModifier.effects` 倍率缩放
4. **周末加成**: SLACK +5 energy, STUDY +3 interview
5. **状态条件**: buff/debuff 倍率叠加（含 CORE_MEMBER 仅工作行动生效规则）
6. **技能被动**: 技能树效果乘数/折扣


## 7. 目录结构规范 (Directory Structure)

| 目录 | 职责 |
|------|------|
| `lib/state/` | Riverpod Notifier 定义 (`game_notifier.dart`, `audio_notifier.dart`, `providers.dart`) |
| `lib/models/` | 数据模型类（全部含 `fromJson`/`toJson`） |
| `lib/logic/` | 纯逻辑函数（无副作用、无 Widget 依赖） |
| `lib/data/` | JSON 数据加载门面 (`game_data.dart`，10 类数据同步 getter) |
| `lib/services/` | 外部服务封装 (`save_service.dart`, `audio_manager.dart`) |
| `lib/screens/` | 全屏页面 Widget (`game_screen.dart`, `title_screen.dart`, `ending_screen.dart`, `video_intro_screen.dart`, `tutorial_screen.dart`) |
| `lib/widgets/` | 可复用 UI 组件。`sidebar.dart` 包含 `LeftDatePanel`（日期面板，含特殊日标记图例）和 `RightStatsPanel`（属性面板）。`qte_game.dart` 和 `qte_result_overlay.dart` 为 QTE 系统组件。`crt_overlay.dart` 和 `buff_bar.dart` 存在但已不用于当前横屏布局。 |
| `lib/theme/` | 视觉常量 (`colors.dart`, `typography.dart`, `app_theme.dart`, `neon_styles.dart`) |
| `lib/utils/` | 工具函数 (`clamp.dart`, `weekend.dart`) |
| `assets/data/` | 10 个 JSON 数据文件（只读） |
| `assets/backgrounds/` | 8 个背景图 PNG |
| `assets/audio/` | BGM + SFX 音频文件 |
| `assets/video/` | 开场视频 (`intro.mp4`) |
| `test/` | 单元 + 集成测试（248 cases, 15 文件） |


## 8. 扩展系统 (Extension Systems)

### 8.1 日间修饰符系统
- **数据**: `assets/data/modifiers.json` (12个)
- **逻辑**: `GameNotifier.assignDayModifier()` — OPENING 阶段 70% 概率分配
- **效果链**: `action_resolver.dart` 第 3 步

### 8.2 打断系统
- **数据**: `assets/data/interruptions.json` (8个)
- **逻辑**: `GameNotifier.selectAction()` — MORNING→AFTERNOON 25% 触发
- **UI**: `editor.dart` → `InterruptionContent`

### 8.3 怀疑度压力系统
- **数据**: `assets/data/pressure-events.json` (6个)
- **逻辑**: `GameNotifier.checkSuspicionPressure()` — suspicion ≥ 70 概率触发
- **UI**: `editor.dart` → `_PressureDialog`

### 8.4 状态条件系统 (Buff/Debuff)
- **数据**: `assets/data/status-conditions.json` (4 buff + 4 debuff)
- **逻辑**: `lib/logic/status_evaluator.dart` → `computeActiveStatuses()`
- **UI**: `lib/widgets/buff_bar.dart` → `BuffBar` (图标 + Tooltip)
- **效果链**: `action_resolver.dart` 第 5 步

### 8.5 连选惩罚
- **数据**: `action_resolver.dart` 内建 `streakTable`
- **逻辑**: `action_resolver.dart` 第 1 步
- **UI**: `editor.dart` → `_ActionCard` 右上角连选角标

### 8.6 即时抓包
- **逻辑**: `action_resolver.dart` → `_checkSpotCheck()`
- **效果链**: `action_resolver.dart` 第 2 步

### 8.7 技能系统
- **数据**: `assets/data/skills.json` (12 个, 4 分支 × 3 层)
- **货币**: 成长点 — `GameNotifier.earnSkillPoints()` (Day 7/14/21)
- **购买**: `GameNotifier.purchaseSkill()` — 前置检查 + 扣减
- **UI**: `lib/widgets/week_review.dart` → `WeekReview` 弹窗
- **效果链**: `action_resolver.dart` 第 6 步

### 8.8 事件分类与背景图
- **数据**: `assets/data/event-categories.json` (4 类)
- **映射**: daily_work / office_politics / tech_crisis / personal_growth → 对应 PNG

### 8.9 开场视频系统 (Patch-F16)
- **触发**: 仅 `[ NEW GAME ]` — CONTINUE 不播放
- **状态**: `GameState.showIntroVideo`（瞬态 UI 标志，不序列化）
- **逻辑**: `GameNotifier.startIntroVideo()` → `VideoIntroScreen` → `finishIntroVideo()`
- **UI**: `lib/screens/video_intro_screen.dart` — 全屏视频 + 1000ms 淡入淡出 + 毛玻璃文案打字机效果 + 点击跳过
- **依赖**: `video_player: ^2.9.2`（lock/cache 可解析到更新的兼容版本）

### 8.10 QTE 快速反应事件系统 (Patch-F17)
- **数据模型**: `lib/models/qte_config.dart` — `QteConfig` 类 + `QteResult` 枚举（perfect/good/miss）
- **GameEvent 扩展**: 可选字段 `qteConfig: QteConfig?`，非空时 EventContent 渲染 QteGame 替代 A/B 按钮
- **事件数据**: `assets/data/events.json` 中 EV_061~EV_065（5 个 QTE 事件），事件总数 65
- **触发机制**:
  - 随机抽取：QTE 事件混入事件池，由 `sampleEvent()` 按权重抽取
  - 固定天数：Day 5/10/15/20/25 强制 QTE（`triggerEvent()` 检测）
- **难度缩放**: 随怀疑度动态调整
  - `effectiveSpeed(suspicion)` = speedBase + suspicion × speedSuspicionScale
  - `effectiveTimeLimit(suspicion)` = max(timeLimitMs − suspicion × timeLimitSuspicionReduce, 2500)ms
- **移动轨迹**: 3 阶段 AnimationController（0.0→1.0）
  - 0-25%: 水平正弦波扫描
  - 25-70%: 预计算随机路点步进
  - 70-100%: 螺旋收束至中心
- **判定**: 两个 GlobalKey 获取容器/方块 RenderBox 实时位置 → 欧几里得距离
  - Perfect ≤ 8px / Good ≤ 24px / Miss > 24px 或超时
- **UI**: `lib/widgets/qte_game.dart`（游戏区 + 判定框 + 锁定按钮 + 倒计时）+ `lib/widgets/qte_result_overlay.dart`（粒子/脉冲/嘲讽）
- **逻辑**: `GameNotifier.resolveQteEvent(eventId, result)` — 应用 stat deltas → SETTLEMENT
- **GameScreen 适配**: QTE 事件进入时自动折叠终端
- **副作用**: 结果效果链走现有 clamp 铁律，日志分级输出


## 9. 核心约束 (Hard Constraints)

- **无状态组件**: UI 组件为 `ConsumerWidget`，仅从 Provider 读取数据并渲染。
- **数值钳位**: 所有对 `energy`/`kpi`/`interview`/`suspicion` 的更新必须经过 `clamp()`。
- **副作用隔离**: 结局跳转逻辑仅在 `runSettlement()` 中处理，禁止在行动按钮回调中直接触发 Ending。
- **存档 Key 锁定**: SharedPreferences key 固定为 `frontend-survival-save`。
- **结局后清除**: `EndingScreen` 在 glitch/reveal 动画完成时清除存档。
- **版本兼容**: 存档 `version` 不匹配 → 丢弃，视为新游戏。
- **copyWith 陷阱**: 可空字段使用 sentinel 模式，确保显式传 `null` 不被 `??` 吞掉。


## 10. 音频架构 (Audio System)

- **库**: `audioplayers` (`AudioPlayer`)
- **资源目录**: `assets/audio/bgm/` (3 files) + `assets/audio/sfx/` (5 files)
- **管理器**: `lib/services/audio_manager.dart` (singleton)
- **状态**: 独立 `AudioNotifier` (`muted`, `bgmVolume`, `sfxVolume`, `currentBgm`)
- **Crossfade**: BGM 切换时 20 步×50ms = 1s 渐出 + 1s 渐入
- **循环**: BGM 使用 `ReleaseMode.loop` 无缝循环
- **音频焦点**: BGM Player `AndroidAudioFocus.gain`；SFX Player `AndroidAudioFocus.none`（不中断 BGM）
- **降级**: 音频文件缺失 → catch 静默，游戏正常运行
- **跨平台**: SFX/BGM 文件名通过 `_sfxFiles` / `_bgmFiles` 映射表解析，迁移格式只需改映射表

### 10.1 BGM 场景映射

| 相位 / 状态 | BGM | 触发位置 |
|------------|-----|---------|
| TITLE | `title.mp3` (~60s) | title_screen `initState` |
| OPENING / MORNING / AFTERNOON / SETTLEMENT (正常) | `daily.mp3` (~60s) | game_screen `_syncBgm` |
| energy≤20 或 kpi≤20 (危险) | `tension.mp3` (~102s) | game_screen `_syncBgm`（替换 daily） |
| ENDING | 停止所有 BGM | ending_screen `initState` |

### 10.2 SFX 清单

| SFX ID | 文件 | 触发时机 | 播放位置 |
|--------|------|---------|---------|
| `click` | `click.ogg` | 所有交互按钮 `onTapDown` | editor / title_screen / top_bar / week_review / game_screen / ending_screen |
| `event` | `event.wav` | 普通随机事件弹窗出现 | game_screen `_tryPlaySfx` |
| `alert` | `alert.wav` | 高危事件 / 打断 / 压力事件出现 | game_screen `_tryPlaySfx` |
| `glitch` | `glitch.wav` | BE 结局 GlitchPhase 开始 | ending_screen `initState` |
| `success` | `success.wav` | GE/NE/HE 结局 RevealPhase 开始 | ending_screen `initState` |

### 10.3 SFX 去重机制

`game_screen.dart` → `_GameLayoutState._tryPlaySfx()` 使用 `_sfxPlayedKey` 追踪当前弹窗唯一标识（格式：`event:${id}` / `intr:${id}` / `press:${id}`），同一弹窗只触发一次 SFX，弹窗消失后重置。


## 11. 存档架构 (Save System)

- **方案**: `SharedPreferences` + JSON 序列化
- **Key**: `frontend-survival-save`
- **保存时机**: SETTLEMENT 判无结局后更新 `savedAt` 并进入下一天 `OPENING`；`GameScreen` post-frame 调用 `SaveService.save()`
- **恢复时机**: TITLE 阶段检测 `SaveService.hasSave()`
- **清除时机**: `EndingScreen` reveal 动画完成后调用 `SaveService.clear()`
- **版本兼容**: `SaveService.load()` 内部校验 `version` 字段
- **实现**: `lib/services/save_service.dart`


## 12. 动画系统 (Animation System)

所有动画时长统一为 **300ms**（除特殊标注外），`Curves.easeOut` 默认缓动。

### 12.1 相位切换

`lib/widgets/editor.dart` → `Editor.build()` 使用 `AnimatedSwitcher(300ms)` + `transitionBuilder`：

- **进入**: `ScaleTransition(0.9→1.0)` + `FadeTransition(0→1)`
- **退出**: `ScaleTransition(1.0→0.9)` + `FadeTransition(1→0)`（反向镜像）

每个相位内容通过 `ValueKey(phase+interruption+eventId)` 区分。

### 12.2 弹窗弹出

`lib/widgets/editor.dart` → `_PopIn` 组件：延迟 300ms 后播放 `scale 0.9→1.0 + fade 0→1`（300ms）。

- **事件/打断/高压弹窗**：使用 Editor 级 `AnimatedSwitcher` 统一处理进出，不再套 `_PopIn`
- **行动卡片**：套 `_PopIn(delayMs: 500)` 实现背景先换→卡片后出的次序感

### 12.3 背景交叉淡入淡出

`lib/widgets/editor.dart` → 背景图 `AnimatedSwitcher(500ms, ValueKey(bgPath))` + `SizedBox.expand`。8 张背景图在 `GameData.init()` 时预加载到内存（`rootBundle.load`）。

### 12.4 结算加载圈

`SettlementContent` 包裹 `TweenAnimationBuilder` opacity 淡入（300ms）。

### 12.5 Buff/技能芯片弹性入场

`lib/widgets/sidebar.dart` → 每个 chip 包裹 `TweenAnimationBuilder(Curves.elasticOut, 350ms)` scale 0→1。

### 12.6 终端日志滑入

`lib/widgets/terminal_widget.dart` → 每条日志 `TweenAnimationBuilder` slide-up + fade-in（300ms）。

### 12.7 终端折叠/展开

`lib/screens/game_screen.dart` → `_CollapsibleTerminal` 使用 `AnimatedSize(250ms, easeOut)`。

### 12.8 周度复盘面板弹出

`lib/widgets/week_review.dart` → 面板包裹 `TweenAnimationBuilder` scale+fade（300ms）。


## 13. 毛玻璃系统 (Glassmorphism)

`lib/widgets/editor.dart` → `GlassPanel` 组件，全局统一参数：

| 参数 | 值 |
|------|----|
| 模糊 sigma | 12.0 (X/Y) |
| 遮罩底色 | `Colors.black.withValues(alpha: 0.4)` |
| 默认边框 | `Border.all(Colors.white.withValues(alpha: 0.1), width: 1)` |

**层级结构**: `RepaintBoundary → ClipRRect → BackdropFilter → Container(半透明) → child`

`RepaintBoundary` 防止触摸/滑动时 Flutter 丢弃 BackdropFilter 图层。应用面板：Opening、Action Cards、Event、Interruption、Pressure。

### 13.1 最小不透明度

`_PopIn` 的 `Opacity` 使用 `0.01 + 0.99 * value`，确保 opacity 永不为 0，BackdropFilter 图层从第一帧就保持渲染，模糊效果与面板缩放同步。


## 14. 触觉反馈与按压缩放 (Haptic & Press-Scale)

所有交互按钮统一实现 **按下缩小 + 线性马达震动**。

**`_TapButton` / `_WeekButton`** 复用组件：

```
AnimatedScale(0.93↔1.0, 100ms, easeInOutCubic)
  → GestureDetector(onTapDown/onTapUp/onTapCancel)
    → 子组件
```

`onTapDown` 时调用 `HapticFeedback.lightImpact()`（轻量触觉，调用线性马达）。

应用范围：

| 组件 | 缩放比 | 位置 |
|------|--------|------|
| 行动卡片 `_ActionCard` | 0.95 | `lib/widgets/editor.dart` |
| 事件选项 `_EventOption` | 0.97 | `lib/widgets/editor.dart` |
| 打断/高压"知道了" | 0.93 | `lib/widgets/editor.dart` (_TapButton) |
| 技能节点 `_SkillNode` | 0.93 | `lib/widgets/week_review.dart` |
| 周度复盘按钮 | 0.93 | `lib/widgets/week_review.dart` (_WeekButton) |

行动卡片和事件选项的 `onTap` 有 **150ms 延迟**（`Future.delayed`），确保按压回弹动画完整播放后相位才切换。


## 15. Overscroll 防护

所有滚动组件使用 `ClampingScrollPhysics()` 并包裹 `ScrollConfiguration(overscroll: false)`，彻底禁用 iOS 回弹和 Android 12+ 拉伸形变，防止 Overscroll 击穿 BackdropFilter。

涉及文件：`lib/widgets/editor.dart` → `ActionContent` (GridView)、`OpeningContent` (SingleChildScrollView)、`EventContent` (SingleChildScrollView)。


## 16. 终端系统 (Terminal)

### 16.1 自动滚动

`lib/widgets/terminal_widget.dart` → `TerminalWidget` 持有 `ScrollController`，每次 `build()` 通过 `addPostFrameCallback` 自动 `animateTo(maxScrollExtent, 200ms)`。

### 16.2 合并工具栏

`lib/screens/game_screen.dart` → `_CollapsibleTerminal` 合并了原来的独立 header 行（`System Log // Output_Channel_0`）和折叠按钮行为一栏：`[▼] LOG // CH0 (##) TERMINAL ▼`。


## 17. 技能撤销 (Skill Undo)

`lib/state/game_notifier.dart` → `refundSkill(skillId)` — 退还成长点并移除技能。

`lib/widgets/week_review.dart` → `WeekReview` 管理 `_pendingUndoSkillId` 状态：
- 首次点击已解锁技能 → 红色高亮"再次点击撤销"
- 二次点击同一技能 → 执行 `refundSkill()` 并清除待撤销状态
- 点击其他技能/关闭面板 → 自动清除待撤销状态


## 18. 动态主题系统 (Game-State Aware Theme)

`lib/state/theme_provider.dart` → `GameTheme` 类 + Riverpod Provider，根据 `GameState` 纯派生三套主题。

### 18.1 主题模式

| 模式 | 触发条件 | 优先级 |
|------|---------|--------|
| **Dark (暗色)** | AFTERNOON / EVENT / SETTLEMENT / TITLE | 3 (默认) |
| **Light (浅色)** | MORNING / OPENING / interruption != null | 2 |
| **Danger (暗红)** | highRisk event / suspicionPressure / energy ≤ 10 / kpi ≤ 10 | 1 (最高) |

### 18.2 三套色值

| Token | Dark | Light | Danger |
|-------|------|-------|--------|
| bgDeep | `#0D0D0D` | `#D8D8E2` | `#140408` |
| bgPanel | `#111116` | `#DEDEE6` | `#1E0610` |
| bgSurface | `#18181F` | `#E4E4EA` | `#280A18` |
| terminalBg | `#0A0A0F` | `#D0D0DA` | `#0C0204` |
| barBg | `#1A1A24` | `#CCCCD6` | `#240610` |
| glassOverlay | `black 0.5` | `white 0.25` | `深红 0.5` |
| glassBorder | `white 0.15` | `white 0.35` | `neonRed 0.5` |
| dividerColor | `#2A2A35` | `#C0C0CC` | `#300C18` |

Light 主题下霓虹色（neon* ～80% 亮度）和文字色（textPrimary → 深色）会有适配性调整，以在亮背景上保持可读性。Dark/Danger 保持原始高亮值。

### 18.3 过渡动画

- `app.dart` 使用 `AnimatedTheme(duration: 500ms, curve: easeOut)` 包裹 MaterialApp
- UI 组件使用 `AnimatedContainer(duration: 500ms)` 平滑过渡背景色
- `GlassPanel` 的 overlay/border 随主题变化，毛玻璃效果在浅色模式下使用白色半透明叠加

### 18.4 关键约束

- **纯派生**: `GameTheme.compute()` 是纯函数，不存储任何状态，主题随 GameState 自动变化
- **自动复位**: 进入 OPENING 相位时自动重新计算，不可能"卡死"在 Danger 模式
- **Provider 隔离**: `themeProvider` 独立于 `gameProvider`，只读不写

---

## Current Implementation Reconciliation (2026-05-30)

This section is authoritative for the current Flutter implementation and supersedes stale historical statements elsewhere in this architecture document.

- `GameState` currently has 24 fields. `showIntroVideo` is transient UI state and is intentionally not serialized.
- `GameData.init()` loads 10 JSON data files and preloads 8 background PNGs: `morning`, `afternoon`, `daily-work`, `office-politics`, `tech-crisis`, `personal-growth`, `high-risk`, and `QTE`.
- Event data contains 65 events, 14 high-risk events, and 5 QTE events (`EV_061`-`EV_065`).
- QTE events keep two schema-compatible `options`; QTE result deltas are resolved through `QteConfig`.
- The active buff/debuff HUD is `_RightBuffBar` inside `lib/widgets/sidebar.dart`; `lib/widgets/buff_bar.dart` is retained legacy code.
- Action cards are implemented by `_ActionCard`, not `_ActionTile`.
- The shared glass widget is public `GlassPanel` in `lib/widgets/editor.dart`, with themed `glassOverlay` and `glassBorder`.
- `video_player` is constrained in `pubspec.yaml` as `^2.9.2`; the resolved package version may be newer in the lockfile/cache.
- Save writes are initiated by `GameScreen` post-frame after no-ending settlement reaches `OPENING`; `runSettlement()` itself only mutates state.
- Save clear is initiated by `EndingScreen` after its reveal animation completes.
- Current validation baseline: `flutter analyze` zero issues, `flutter test` 248 passing tests across 15 Dart files.
