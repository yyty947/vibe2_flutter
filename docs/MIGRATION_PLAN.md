# Flutter 迁移计划：《前端生死劫》 Web → Android

> **源项目路径**: `C:\Users\y\Desktop\vibecoding\vibe2`
> **目标项目路径**: `C:\Users\y\Desktop\vibecoding\vibe2_flutter`
> **源项目版本**: v1.3.0
> **目标平台**: Android (Flutter)
> **计划创建日期**: 2026-05-03
> **预期总工时**: 按 20 个 Milestone 分阶段交付

---

## 1. 技术栈对照表

### 1.1 核心框架

| Web 技术 | Flutter 替代方案 | 选型理由 |
|-----------|-----------------|---------|
| Next.js 16 (App Router) | Flutter `MaterialApp` + `GoRouter` | 纯客户端应用，不需要 Next.js 的 SSR/路由文件系统。GoRouter 支持声明式路由和 deep link |
| React 19 (组件模型) | Flutter `Widget` (StatelessWidget / StatefulWidget) | Flutter 万物皆 Widget，与 React 组件化思想一致 |
| Tailwind CSS 4 | Flutter `ThemeData` + `ThemeExtension` + 自定义 `BoxDecoration` | Flutter 通过 Theme 系统统一管理颜色/字体/间距；Tailwind 的工具类思想无法直接映射，改用语义化组件 + 常量配置 |

### 1.2 状态管理

| Web 技术 | Flutter 替代方案 | 选型理由 |
|-----------|-----------------|---------|
| Zustand 5 (+ persist middleware) | **Riverpod** (`StateNotifierProvider` / `NotifierProvider`) + 手动 JSON 持久化 | Riverpod 与 Zustand 最接近：轻量、支持外部逻辑抽离、不可变状态更新、不依赖 Widget 树。Zustand 的 `persist` 中间件在 Flutter 侧需手动实现到 SharedPreferences |
| `useGameStore` (单一大 Store) | 单一 `GameNotifier` (Riverpod `Notifier<GameState>`) | 保持与 Web 端一致的单数据源架构，避免分拆导致的同步问题 |
| `useAudioStore` (独立 Store) | 独立 `AudioNotifier` (Riverpod `Notifier<AudioState>`) | 与 Web 端一致，音频状态不混入 GameState，不持久化 |

### 1.3 持久化

| Web 技术 | Flutter 替代方案 | 选型理由 |
|-----------|-----------------|---------|
| `localStorage` (key: `frontend-survival-save`) | **SharedPreferences** + `dart:convert` (JSON) | 存档为单一 JSON 字符串 < 10KB，SharedPreferences 读写简单、同步读取无需异步初始化。备选: `hive` 若后续存档体积增长 |
| Zustand `persist` 自动写入 | 手动在 `GameNotifier` 状态更新后调用 `_saveToDisk()` | Flutter 无可直接替代的自动持久化中间件，需显式调用 |

### 1.4 动画

| Web 技术 | Flutter 替代方案 | 选型理由 |
|-----------|-----------------|---------|
| Framer Motion (`motion.div`, `AnimatePresence`) | Flutter `AnimatedWidget` / `AnimatedBuilder` / `AnimationController` + `Tween` | Flutter 内置动画系统足以覆盖所有效果（淡入淡出、缩放、弹跳、抖动） |
| 打字机效果 (`useTypewriter`) | 自定义 `TypewriterController` (Timer-based) | 使用 `Timer.periodic` 逐字输出 + `AnimatedBuilder` 触发重建 |
| 数值动画 (`useNumberAnimation`, `useAnimatedNumber`) | `TweenAnimationBuilder<int>` + `Curves` | Flutter 内置的 Tween 动画天然支持数值插值，比 Web 版更简洁 |
| CSS keyframes (`@keyframes`) | `AnimationController.repeat()` + `Tween` | Flutter 通过 AnimationController 的 repeat 模式替代 CSS 循环动画 |

### 1.5 音频

| Web 技术 | Flutter 替代方案 | 选型理由 |
|-----------|-----------------|---------|
| Howler.js (Web Audio) | **`audioplayers`** (`AudioPlayer`) | 轻量、支持 Android/iOS、支持循环播放、音量控制、淡入淡出（通过定时器手动实现 crossfade） |
| Howler `fade()` | 手动 `Timer` + 逐步调整 `audioPlayer.setVolume()` | audioplayers 无内置 crossfade，需用 ~100ms 间隔的定时器逐步调整 |
| 懒加载（首次交互触发） | `AudioPlayer` 实例在首次 play 时惰性创建 | 与 Web 端一致策略 |

### 1.6 图标

| Web 技术 | Flutter 替代方案 | 选型理由 |
|-----------|-----------------|---------|
| Lucide React (SVG) | **`lucide_icons`** 包 (Flutter) | 直接对应 Lucide 图标库的 Flutter 版本，API 相同 |

### 1.7 数据文件

| Web 技术 | Flutter 替代方案 | 选型理由 |
|-----------|-----------------|---------|
| `src/data/*.json` (Next.js import) | `assets/data/*.json` + `rootBundle.loadString()` | Flutter 通过 `pubspec.yaml` 声明 assets 目录，运行时用 `rootBundle` 加载 JSON 字符串后 `jsonDecode()` |
| TypeScript 接口 (`interface`) | Dart 类 + `fromJson`/`toJson` 工厂构造函数 | Dart 没有 TS 的结构子类型，需用 `freezed` 或手写 JSON 序列化代码 |

### 1.8 测试

| Web 技术 | Flutter 替代方案 | 选型理由 |
|-----------|-----------------|---------|
| Playwright (E2E) | **`integration_test`** + `flutter_driver` | Flutter 官方集成测试方案，支持真实设备/模拟器上的 UI 交互测试 |
| 手动测试脚本 (`manual-test.js`) | Dart 单元测试 (`flutter test`) + 纯逻辑测试 | 结局判定/事件抽取等纯逻辑函数可完全用 `package:test` 覆盖，无需设备 |

---

## 2. 资产迁移清单

### 2.1 可直接复用的资产（复制到 Flutter 项目）

| 源路径 | 目标路径 | 说明 |
|--------|----------|------|
| `src/data/actions.json` | `assets/data/actions.json` | 12 个行动定义，结构不变 |
| `src/data/events.json` | `assets/data/events.json` | 65 个事件（含 14 高危、5 QTE），结构已扩展 `qteConfig` |
| `src/data/openings.json` | `assets/data/openings.json` | 30 段开场白，结构不变 |
| `src/data/endings.json` | `assets/data/endings.json` | 5 个结局文案，结构不变 |
| `src/data/modifiers.json` | `assets/data/modifiers.json` | 12 个日间修饰符，结构不变 |
| `src/data/interruptions.json` | `assets/data/interruptions.json` | 8 个打断事件，结构不变 |
| `src/data/pressure-events.json` | `assets/data/pressure-events.json` | 6 个压力事件，结构不变 |
| `src/data/status-conditions.json` | `assets/data/status-conditions.json` | 8 个 buff/debuff，结构不变 |
| `src/data/skills.json` | `assets/data/skills.json` | 12 个技能定义，结构不变 |
| `src/data/event-categories.json` | `assets/data/event-categories.json` | 4 个事件分类，结构不变 |
| `public/backgrounds/*.png` | `assets/backgrounds/*.png` | 8 张氛围背景图（含 `QTE.png`） |
| `public/audio/bgm/*.mp3` | `assets/audio/bgm/*.mp3` | BGM 音乐文件 |
| `public/audio/sfx/*.mp3` | `assets/audio/sfx/*.mp3` | SFX 音效文件 |

### 2.2 需要适配的文件（逻辑相同但语言不同）

| 源文件 | 目标文件 | 适配工作 |
|--------|----------|---------|
| `src/store/useGameStore.ts` (983行) | `lib/state/game_notifier.dart` | Dart 重写：Notifier + 所有 action 方法，效果修正链，状态条件评估 |
| `src/store/useAudioStore.ts` (36行) | `lib/state/audio_notifier.dart` | Dart 重写：音量/mute 管理 |
| `src/logic/endings.ts` (42行) | `lib/logic/endings.dart` | 纯函数，几乎逐行翻译 |
| `src/logic/events.ts` (108行) | `lib/logic/events.dart` | 纯函数，逐行翻译 |
| `src/logic/gameLoop.ts` (62行) | `lib/logic/game_loop.dart` | 纯函数，逐行翻译 |
| `src/logic/actionPool.ts` (135行) | `lib/logic/action_pool.dart` | 纯函数 + shuffle，逐行翻译 |
| `src/logic/audioManager.ts` (153行) | `lib/services/audio_manager.dart` | 用 audioplayers API 替换 Howler.js API |
| `src/hooks/useTypewriter.ts` (259行) | `lib/widgets/typewriter_controller.dart` | 用 Dart Timer 替代 JS setTimeout |
| `src/hooks/useNumberAnimation.ts` (216行) | 内置 `TweenAnimationBuilder<int>` | Flutter 原生支持，代码量大幅减少 |

### 2.3 需要重写的文件（UI 层完全重建）

| 源文件 | 目标文件 | 说明 |
|--------|----------|------|
| `src/app/page.tsx` (178行) | `lib/screens/game_screen.dart` | Flutter Widget 树重建，相位条件渲染 |
| `src/app/layout.tsx` (37行) | `lib/main.dart` | Flutter 入口 + MaterialApp 配置 |
| `src/app/globals.css` (507行) | `lib/theme/app_theme.dart` | CSS → Dart ThemeData / ThemeExtension |
| `src/components/game/TitleScreen.tsx` (163行) | `lib/screens/title_screen.dart` | Matrix 雨用 `CustomPainter` 重写 |
| `src/components/game/Sidebar.tsx` (475行) | `lib/widgets/sidebar.dart` | HUD 面板 Flutter 实现 |
| `src/components/game/Editor.tsx` (516行) | `lib/widgets/editor.dart` | 行动选择 UI + 开场白 + 打断弹窗 |
| `src/components/game/Terminal.tsx` (150行) | `lib/widgets/terminal_widget.dart` | 终端日志滚动 |
| `src/components/game/EventDialog.tsx` (131行) | `lib/widgets/event_dialog.dart` | 事件弹窗 |
| `src/components/game/EndingScreen.tsx` (130行) | `lib/screens/ending_screen.dart` | Glitch 效果 + 结局展示 |
| `src/components/game/BuffBar.tsx` (121行) | `lib/widgets/buff_bar.dart` | Buff/Debuff 图标栏 |
| `src/components/game/WeekReview.tsx` (264行) | `lib/widgets/week_review.dart` | 周度复盘弹窗 |

---

## 3. 分阶段迁移计划

### Milestone 1：项目初始化 + 目录结构

- **目标**：创建 Flutter 项目，建立完整目录结构，配置依赖和 assets
- **涉及文件**：
  - `pubspec.yaml` — 声明所有依赖 (`audioplayers`, `shared_preferences`, `flutter_riverpod`, `go_router`, `lucide_icons`, `freezed`, `json_annotation`, `build_runner`)
  - `lib/main.dart` — MaterialApp + ProviderScope + GoRouter 入口
  - `lib/theme/app_theme.dart` — 色板常量 + Cyberpunk ThemeData 骨架
  - `lib/state/` — 空目录
  - `lib/logic/` — 空目录
  - `lib/widgets/` — 空目录
  - `lib/screens/` — 空目录
  - `lib/services/` — 空目录
  - `assets/data/` — 复制全部 10 个 JSON 文件
  - `assets/backgrounds/` — 复制全部 7 个 PNG 文件
  - `assets/audio/bgm/` — 复制 BGM 文件
  - `assets/audio/sfx/` — 复制 SFX 文件
- **完成标准**：
  - `flutter analyze` 零错误通过
  - `flutter run` 在 Android 模拟器上显示空白黑屏（`#0D0D0D` 背景）
  - `rootBundle.loadString('assets/data/actions.json')` 可成功读取并解析为 Dart Map
- **依赖**：无
- **需调用 Flutter MCP 执行的命令**：
  - `mcp__dart__create_project` — 创建 Flutter 项目（不要用 `flutter create` bash 命令）
  - `mcp__dart__add_roots` — 注册项目根路径到 Dart MCP server
  - `mcp__dart__pub` — 执行 `pub get` 安装依赖（不要用 `flutter pub get` bash 命令）
- **执行前需读取 Flutter Skills**：无（纯项目初始化）
- **M1 实际执行回顾**（已完成）：
  - ❌ 未使用 `mcp__dart__create_project`（用了 `flutter create` bash）
  - ❌ 未使用 `mcp__dart__add_roots`（事后补加）
  - ❌ 未使用 `mcp__dart__pub`（用了 `flutter pub get` bash）
  - ✅ 后续 M2-M3 已改用 `mcp__dart__run_tests`

---

### Milestone 2：核心数据模型 + 工具函数

- **目标**：在 Dart 中定义所有数据接口（等同于 TS interface），实现 clamp 和周末判断
- **涉及文件**：
  - `lib/models/game_state.dart` — `GameState` 类（全部 22 个字段），含 `INITIAL_STATE` 常量
  - `lib/models/action_def.dart` — `ActionDef` 类 + `fromJson`
  - `lib/models/game_event.dart` — `GameEvent`, `EventOption`, `EventEffect` 类 + `fromJson`
  - `lib/models/log_entry.dart` — `LogEntry` 类 + `LogType` 枚举
  - `lib/models/ending_type.dart` — `EndingType` 枚举 + `GamePhase` 枚举
  - `lib/models/action_stats.dart` — `ActionStats` 类
  - `lib/models/day_modifier.dart` — `DayModifier` 类 + `fromJson`
  - `lib/models/interruption.dart` — `Interruption` 类 + `fromJson`
  - `lib/models/pressure_event.dart` — `PressureEvent` 类 + `fromJson`
  - `lib/models/status_condition.dart` — `StatusCondition`, `StatusTrigger`, `StatusEffects` 类 + `fromJson`
  - `lib/models/skill_def.dart` — `SkillDef` 类 + `fromJson`
  - `lib/utils/clamp.dart` — `int clamp(int val, [int min = 0, int max = 100])`
  - `lib/utils/weekend.dart` — `bool isWeekend(int day)` + `WEEKEND_DAYS` 常量集
- **完成标准**：
  - 所有 JSON 数据文件可用 `fromJson` 工厂构造函数成功反序列化
  - `clamp(-5) == 0`, `clamp(120) == 100`, `clamp(50) == 50` 单元测试通过
  - `isWeekend(6) == true`, `isWeekend(5) == false`, `isWeekend(13) == true` 单元测试通过
  - `flutter test` 所有模型和工具函数测试通过（≥ 15 个 test case）
- **依赖**：M1

---

### Milestone 3：游戏状态管理 (Riverpod Notifier)

- **目标**：用 Riverpod Notifier 实现完整 GameState 管理，包含所有 action 方法骨架
- **涉及文件**：
  - `lib/state/game_notifier.dart` — `GameNotifier extends Notifier<GameState>` + 全部 action 方法
    - 阶段转换: `startNewGame()`, `continueGame()`, `skipOpening()`, `selectAction()`, `selectEventOption()`, `skipEvent()`, `runSettlement()`, `restart()`
    - 修饰符/打断: `assignDayModifier()`, `acknowledgeInterruption()`
    - 压力事件: `checkSuspicionPressure()`, `acknowledgePressure()`
    - 状态条件: `evaluateStatusConditions()`
    - 技能: `earnSkillPoints()`, `purchaseSkill()`, `spendPointsForSuspicion()`, `closeWeekReview()`
    - 辅助: `addLog()`, `applyEffects()`, `setPhase()`
  - `lib/state/audio_notifier.dart` — `AudioNotifier extends Notifier<AudioState>`
  - `lib/data/game_data.dart` — 静态数据加载门面（一次性解析所有 JSON）
  - `lib/state/providers.dart` — 导出所有 provider 实例和类型别名
- **完成标准**：
  - `gameProvider` 可被 Widget 正常读取（`ref.read(gameProvider)` 返回 `GameState`）
  - `ref.read(gameProvider.notifier).startNewGame()` 后，`phase = OPENING`, `day = 1`
  - `ref.read(gameProvider.notifier).selectAction('WRITE_CODE')` 后，`phase` 正确转换且 `energy` 通过 clamp
  - `ref.read(gameProvider.notifier).addLog('INFO', 'test')` 后，`logs` 包含新条目
  - 所有公共 action 方法有对应的单元测试（≥ 20 个 test case）
- **依赖**：M2
- **需调用 Flutter MCP 执行的命令**：
  - `flutter analyze`（shell）— 每次修改后验证零错误
  - `mcp__dart__run_tests` — 每次测试编写后运行验证
  - `mcp__dart__dart_format` — 提交前格式化所有 Dart 文件
- **执行前需读取 Flutter Skills**：
  - `flutter-apply-architecture-best-practices` — 写状态管理层前读取，确认 Riverpod Notifier 与推荐 MVVM 模式的差异及适用场景
- **M3 实际执行回顾**（已完成）：
  - ❌ 未在编码前读取 `flutter-apply-architecture-best-practices` skill
  - ⚠️ Skill 推荐 MVVM + `ChangeNotifier`，实际使用 Riverpod `Notifier`（与 Web Zustand 架构一致，属于合理差异）
  - ⚠️ Skill 推荐 `ui/features/[name]/views/` 和 `view_models/` 特征分组结构，实际使用 `screens/` + `widgets/` 布局分组（适合游戏单页面架构）
  - ⚠️ `GameState.copyWith` 中 nullable 字段使用 sentinel 模式修复了 `null ?? original` 吞掉显式 null 的 Bug

---

### Milestone 4：游戏循环状态机 + 相位验证

- **目标**：实现精确的 7 相位状态机，所有转换验证通过
- **涉及文件**：
  - `lib/logic/game_loop.dart` — 移植 `isValidTransition()`, `getNextPhase()`, `LEGAL_TRANSITIONS` 映射
  - `lib/state/game_notifier.dart` — 在 `GameNotifier` 的每个阶段转换 action 中加入 `isValidTransition` 断言
- **完成标准**：
  - 所有合法转换返回 `true`：`TITLE→OPENING`, `OPENING→MORNING`, `MORNING→AFTERNOON`, `AFTERNOON→EVENT`, `EVENT→SETTLEMENT`, `SETTLEMENT→ENDING`, `SETTLEMENT→OPENING`, `ENDING→TITLE`
  - 所有非法转换返回 `false`：`MORNING→TITLE`, `EVENT→OPENING`, `TITLE→MORNING` 等（≥ 15 个非法组合）
  - 完整游戏循环可运行：`TITLE → OPENING → MORNING → AFTERNOON → EVENT → SETTLEMENT → OPENING (Day 2)`
  - `flutter test` 状态机测试全部通过（≥ 25 个 test case）
- **依赖**：M3
- **需调用 Flutter MCP 执行的命令**：
  - `flutter analyze`（shell）— 验证状态机代码零错误
  - `mcp__dart__run_tests` — 运行状态机单元测试
- **执行前需读取 Flutter Skills**：无（纯逻辑层，不涉及 UI 或数据）

---

### Milestone 5：结局判定算法

- **目标**：移植 `checkDailyEnding()` 和 `checkFinalEnding()`，确保优先级正确（Patch-010, Patch-011）
- **涉及文件**：
  - `lib/logic/endings.dart` — 纯函数，逐行翻译 TS 版本
- **完成标准**：
  - `checkDailyEnding` (energy=0) → `BE_DEATH`
  - `checkDailyEnding` (kpi=0) → `BE_FIRED`
  - `checkDailyEnding` (interview=85, suspicion=30) → `GE_OFFER` （提前跳槽）
  - `checkDailyEnding` (interview=85, suspicion=90) → `null` （被封锁的跳槽，Patch-F02）
  - `checkFinalEnding` (kpi=85, suspicion=20, energy=40) → `HE_KING` （内卷之王）
  - `checkFinalEnding` (interview=65, suspicion=40) → `GE_OFFER` （Day 30 跳槽）
  - `checkFinalEnding` (interview=65, suspicion=75) → 跳过 GE_OFFER（怀疑度门槛 `suspicion < 70`）
  - `checkFinalEnding` (kpi=40, suspicion=50, energy=30) → `NE_PEACE` （和平分手）
  - `checkFinalEnding` (kpi=10, suspicion=80, energy=5) → `BE_FIRED` （兜底，Patch-011）
  - `flutter test` 结局判定测试全部通过（≥ 20 个 test case，覆盖所有 5 种结局 + 边界条件）
- **依赖**：M2（数据模型）
- **需调用 Flutter MCP 执行的命令**：
  - `mcp__dart__run_tests` — 运行结局判定全套测试
- **执行前需读取 Flutter Skills**：无（纯逻辑函数，无 UI 或 IO）

---

### Milestone 6：行动系统（含效果修正链）

- **目标**：实现 12 行动数据加载、动态行动池 (`sampleActionPool`)、完整效果修正链
- **涉及文件**：
  - `lib/logic/action_pool.dart` — `sampleActionPool()` 移植
  - `lib/logic/action_resolver.dart` — 效果修正链（连选惩罚 `getStreakAdjustedEffects` → 即时抓包 `checkSpotCheck` → 日间修饰符 `applyModifierToDeltas` → 状态条件 `applyStatusToDeltas` → 技能 `applySkillToDeltas` → 周末加成）
  - `lib/state/game_notifier.dart` — 完善 `selectAction()` 方法
  - `lib/data/action_repository.dart` — JSON 加载 + 内存缓存
- **完成标准**：
  - `sampleActionPool()` 返回恰好 4 个行动，且包含 ≥2 个核心行动
  - `sampleActionPool()` 当 energy≤20 时，`FIX_BUG` 不出现在结果中
  - `sampleActionPool()` 当 `skills` 包含 `TECH_T3` 且 energy>45 时，`ARCH_REDESIGN` 可作为候选
  - 连选 `SLACK` 第 3 次 → energy 收益从 20 衰减为 8（见 `STREAK_EFFECTS` 表）
  - instant spot check：suspicion ≥ 85 时选 STUDY，有高概率触发额外惩罚
  - 周末选 SLACK 额外 +5 energy
  - `flutter test` 行动系统测试全部通过（≥ 25 个 test case）
- **依赖**：M3, M5
- **需调用 Flutter MCP 执行的命令**：
  - `mcp__dart__run_tests` — 运行行动系统全套测试（≥25 case）
  - `flutter analyze`（shell）— 验证效果修正链代码零错误
- **执行前需读取 Flutter Skills**：无（纯逻辑层）

---

### Milestone 7：静态数据迁移 + JSON 加载基础设施

- **目标**：建立 JSON 资产加载机制，验证所有 10 个数据文件能正确解析
- **涉及文件**：
  - `lib/data/game_data.dart` — 统一数据加载门面，提供 `loadActions()`, `loadEvents()`, `loadOpenings()` 等静态方法
  - `lib/data/data_loader.dart` — `rootBundle.loadString()` 封装 + 缓存
- **完成标准**：
  - `loadActions()` 返回 12 个 `ActionDef`，第一个是 `WRITE_CODE`
  - `loadEvents()` 返回 65 个 `GameEvent`，其中 14 个 `highRisk == true`
  - `loadOpenings()` 返回 30 个 key 的 Map（Day 1 ~ Day 30）
  - `loadEndings()` 返回 5 个 ending 的 Map（BE_DEATH, BE_FIRED, GE_OFFER, NE_PEACE, HE_KING）
  - `loadModifiers()` 返回 12 个 `DayModifier`
  - `loadInterruptions()` 返回 8 个 `Interruption`
  - `loadPressureEvents()` 返回 6 个 `PressureEvent`
  - `loadStatusConditions()` 返回 8 个 `StatusCondition`
  - `loadSkills()` 返回 12 个 `SkillDef`
  - `loadEventCategories()` 返回 4 个分类
  - `flutter test` 数据完整性测试全部通过（≥ 20 个 test case）
- **依赖**：M2
- **需调用 Flutter MCP 执行的命令**：
  - `mcp__dart__run_tests` — 验证所有 JSON 文件正确加载和解析（≥20 case）
  - `flutter analyze`（shell）— 验证数据加载代码零错误
- **执行前需读取 Flutter Skills**：
  - `flutter-implement-json-serialization` — 若 M2 未读取，此时补充读取，确保 `fromJson` 遵循 pattern matching 最佳实践

---

### Milestone 8：事件系统（含抽取算法）

- **目标**：完整移植事件抽取算法 `sampleEvent()`，包含权重衰减、高危提升、空事件概率
- **涉及文件**：
  - `lib/logic/events.dart` — `sampleEvent()` 逐行翻译（条件过滤 → 权重调整 → 加权随机 → 浮点兜底）
  - `lib/state/game_notifier.dart` — 完善 EVENT 阶段的自动触发 + `selectEventOption()` 高危效果放大
- **完成标准**：
  - 100 次 `sampleEvent()` (suspicion < 80) → 空事件概率 ≈ 10%
  - 100 次 `sampleEvent()` (suspicion ≥ 80) → 空事件概率 ≈ 5%
  - 已触发事件再次触发概率显著低于未触发事件（50% 权重衰减验证）
  - `highRisk` 事件在 suspicion ≥ 80 时权重 ×3
  - `selectEventOption()` 高危事件 + suspicion ≥ 80 → 负面效果 ×1.5 放大
  - `eventHistory` 正确追加已触发事件 ID
  - `flutter test` 事件系统测试全部通过（≥ 15 个 test case）
- **依赖**：M7
- **需调用 Flutter MCP 执行的命令**：
  - `mcp__dart__run_tests` — 运行事件抽取算法统计测试（≥15 case）
- **执行前需读取 Flutter Skills**：无（纯逻辑 + 数学随机算法）

---

### Milestone 9：存档系统

- **目标**：实现完整的 save/load 循环，与 Web 端行为一致
- **涉及文件**：
  - `lib/services/save_service.dart` — `saveGame()`, `loadGame()`, `clearSave()`, `hasSave()` 封装
  - `lib/state/game_notifier.dart` — SETTLEMENT 阶段触发保存，ENDING 阶段清除存档，TITLE 阶段检测存档
- **完成标准**：
  - SETTLEMENT 无结局后，`SharedPreferences` 中 `frontend-survival-save` key 存在且包含完整 `GameState` JSON
  - 关闭 App 后重新打开，TITLE 画面显示"继续游戏"按钮
  - 点击"继续游戏"恢复所有状态：day, energy, kpi, interview, suspicion, phase, eventHistory, skills, activeStatuses 等
  - 触发任何结局后，`frontend-survival-save` key 被清除
  - 版本号不匹配时（`version != GAME_VERSION`），存档静默丢弃
  - `flutter test` 存档系统测试通过（≥ 10 个 test case，包含 round-trip 验证）
- **依赖**：M3, M5
- **需调用 Flutter MCP 执行的命令**：
  - `mcp__dart__run_tests` — 运行存档 round-trip 测试（≥10 case）
- **执行前需读取 Flutter Skills**：无（SharedPreferences 为标准 Android 库，无对应 Flutter skill）

---

### Milestone 10：赛博朋克视觉基础 + UI 骨架

- **目标**：在 Flutter 中建立完整的赛博朋克终端视觉体系 + 所有屏幕的基础布局
- **涉及文件**：
  - `lib/theme/app_theme.dart` — 完善：ThemeData（Share Tech Mono + Fira Code 字体加载、深黑背景 `#0D0D0D`）、所有霓虹色常量、`NeonTextStyle` 扩展、`GlowBoxDecoration` 扩展
  - `lib/theme/colors.dart` — 完整色板：背景 4 层、霓虹语义色 5 色、文字层级 3 色、边框 2 色
  - `lib/theme/typography.dart` — 字体加载（Google Fonts: Share Tech Mono + Fira Code）、等宽全局设置
  - `lib/widgets/crt_overlay.dart` — CRT 扫描线效果（`CustomPainter` 画 repeating-linear-gradient + 径向暗角）
  - `lib/widgets/glow_text.dart` — 霓虹发光文字组件（`.neon-green`, `.neon-cyan`, `.neon-red`, `.neon-amber` 等效）
  - `lib/widgets/cyber_button.dart` — 赛博朋克按钮（`[ LABEL ]` 格式 + 边框发光 hover）
  - `lib/screens/game_screen.dart` — IDE 布局骨架：TopBar (h=48px) + Row (Sidebar 18% + Column(Editor flex:3 + Terminal flex:1))
  - `lib/widgets/top_bar.dart` — 顶栏：游戏标题、天数进度（CYCLE N/30）、当前相位、重启按钮
  - `lib/widgets/sidebar.dart` — 侧栏骨架：HUD 面板占位
  - `lib/widgets/editor.dart` — 中央区域骨架：各相位内容占位容器
  - `lib/widgets/terminal_widget.dart` — 终端骨架：标签栏 + 日志列表
- **完成标准**：
  - App 启动后看到完整的深黑背景 + CRT 扫描线覆盖层
  - 字号、间距、边框颜色与 Web 版视觉一致（截图对比）
  - TopBar 显示绿色 `FRONTEND SURVIVAL` 标题 + 天数进度
  - Sidebar 占位区域宽度为屏幕宽度的 18%
  - 所有霓虹 CSS 类效果有对应的 Dart `TextStyle` 常量
  - `flutter analyze` 零错误
- **依赖**：M1
- **需调用 Flutter MCP 执行的命令**：
  - `flutter analyze`（shell）— 验证 UI 代码零错误
- **执行前需读取 Flutter Skills**：
  - `flutter-build-responsive-layout` — 写布局前读取，确保 IDE 布局（TopBar+Sidebar+Editor+Terminal）在不同屏幕尺寸下自适应

---

### Milestone 11：标题画面（Matrix 雨 + ASCII Art）

- **目标**：在 Flutter 中用 `CustomPainter` 实现 Matrix 数字雨 + ASCII Art 标题
- **涉及文件**：
  - `lib/screens/title_screen.dart` — 完整标题画面 Widget
  - `lib/widgets/matrix_rain_painter.dart` — `CustomPainter` 实现绿色字符流（含拖尾效果）
  - `lib/widgets/ascii_title.dart` — ASCII Art 标题 + 霓虹闪烁动画
- **完成标准**：
  - Canvas 上可见至少 30 列绿色字符持续下落，头部字符 `#00FF9F` 亮度 0.9，拖尾 8 个字符渐变
  - ASCII Art "FRONTEND SURVIVAL" 标题可见 + `neonFlicker` 闪烁动画（3s 周期）
  - `[ NEW GAME ]` 和 `[ CONTINUE ]` 按钮功能正常
  - 有存档时显示 CONTINUE 按钮，无存档时仅显示 NEW GAME
  - 存档时间戳格式化为 `yyyy-MM-dd HH:mm` 显示
  - 点击 NEW GAME → phase 变为 OPENING, day=1
  - 点击 CONTINUE → 从存档恢复状态
- **依赖**：M9, M10
- **需调用 Flutter MCP 执行的命令**：
  - `flutter analyze`（shell）— 验证 Matrix rain CustomPainter 代码无警告
- **执行前需读取 Flutter Skills**：无（CustomPainter 为标准 Flutter API）

---

### Milestone 12：打字机效果 + 开场白系统

- **目标**：用 Dart Timer 实现打字机逐字输出效果，支持跳过和行间暂停
- **涉及文件**：
  - `lib/widgets/typewriter_text.dart` — 单行打字机 Widget（`Timer.periodic` ~30ms/字、方块光标闪烁、点击跳过）
  - `lib/widgets/typewriter_lines.dart` — 多行打字机 Widget（逐行输出、行间 150ms 暂停）
  - `lib/widgets/editor.dart` — 实现 `OpeningContent`：Day header + modifier tag + pressure warning + 开场白文字
  - `lib/state/game_notifier.dart` — 完善 OPENING 阶段逻辑（`assignDayModifier` + `checkSuspicionPressure`）
- **完成标准**：
  - 开场白文字以 ~30ms/字 速度逐字出现
  - 末尾有青色方块光标闪烁（0.8s blink 周期）
  - 点击文字区域 → 立即显示全部文字，光标消失
  - Day header 正确显示：`DAY-01 / CYCLE-30`
  - 周末 (Day 6/7/13/14/20/21/27/28) 显示 `[WEEKEND]` 标签
  - 日间修饰符正确分配并显示
  - suspicion ≥ 70 时压力事件弹窗正确显示，点击"知道了"后生效
  - 点击 CONTINUE 进入 MORNING 阶段
  - 在 30 组开场白中随机抽样，验证 Day 1 = "高管在全员大会上抛出了'降本增效'..."
- **依赖**：M3, M9, M10
- **需调用 Flutter MCP 执行的命令**：
  - `flutter analyze`（shell）— 验证打字机 Widget 代码无错误
- **执行前需读取 Flutter Skills**：无（Timer-based 逐字输出为核心 Dart 能力）

---

### Milestone 13：行动选择 UI + Terminal 日志

- **目标**：实现 MORNING/AFTERNOON 行动按钮网格 + Terminal 打字日志
- **涉及文件**：
  - `lib/widgets/action_button.dart` — 单个行动按钮（图标 + 标签 + 效果条 + 禁用状态 + 连选角标）
  - `lib/widgets/action_grid.dart` — 2×2 动态布局行动网格
  - `lib/widgets/editor.dart` — 实现 `ActionContent`、`InterruptionContent`、`SettlementContent`
  - `lib/widgets/terminal_widget.dart` — 完善：日志霓虹色分类、`[D##] [TYPE]` 前缀、打字机逐行输出、滚动到底、SPACE 跳过
- **完成标准**：
  - MORNING 阶段显示 2×2（或 3 列）行动按钮网格
  - 每个按钮显示：Lucide 图标 + 行动名 + 效果值（ENR/KPI/INT/SUS 颜色区分）+ 描述
  - `FIX_BUG` 在 energy ≤ 20 时置灰（opacity 0.3 + grayscale + "ENERGY LOW" 标记）
  - 连续选择同一行动 3 次时，按钮右上角显示红色 `×3` 角标
  - 点击行动 → 终端新增一行日志，Prefix `[D01] [COMMIT]` 等
  - 终端日志颜色正确：COMMIT=绿色, BUGFIX=青色, WARNING=琥珀, ALERT=红色
  - AFTERNOON 行动后 → 进入 EVENT 阶段
  - 打断弹窗（25% 概率）正确显示标题/描述/效果 + "知道了"按钮
  - SETTLEMENT 阶段显示 "PROCESSING..." + 旋转加载圈
- **依赖**：M6, M12
- **需调用 Flutter MCP 执行的命令**：
  - `flutter analyze`（shell）— 验证 UI 代码零错误
  - `mcp__dart__run_tests` — 运行行动相关集成测试
- **执行前需读取 Flutter Skills**：
  - `flutter-add-widget-test` — 写行动按钮和日志 Widget 前读取，了解 `WidgetTester` 交互测试方法

---

### Milestone 14：事件弹窗 + 结算完善

- **目标**：完整实现 EVENT 和 SETTLEMENT 阶段的 UI 和逻辑
- **涉及文件**：
  - `lib/widgets/event_dialog.dart` — 事件弹窗（标题 + 描述 + A/B 选项 + 高危红色效果）
  - `lib/screens/game_screen.dart` — 完善相位路由：所有 7 个阶段的 UI 都已就位
  - `lib/state/game_notifier.dart` — 完善 `runSettlement()` (5 步执行：energy drain → checkDailyEnding → 仅 day=30 时 checkFinalEnding → ending 或 day++ 循环)
- **完成标准**：
  - 普通事件：青色边框 + `AlertTriangle` 图标
  - 高危事件：红色边框 + `ShieldAlert` 图标 + `shake` 动画 + 全屏红色径向闪光
  - 选项效果值用正确颜色渲染（绿色=正面，红色=负面/怀疑度）
  - 10% 空事件 → 终端日志 "今天波澜不惊，什么也没发生。"
  - 选选项后 → 立即应用效果（通过 clamp），追加到 eventHistory
  - SETTLEMENT 100ms 后自动执行 `runSettlement()`
  - Day 30 + energy=4 → 触发 BE_DEATH（非 BE_FIRED，Patch-010 验证）
  - 完整 Day 1 → Day 2 循环可在无崩毁下走通
- **依赖**：M8, M13
- **需调用 Flutter MCP 执行的命令**：
  - `mcp__dart__run_tests` — 验证完整 Day 1→Day 2 循环无崩毁
  - `flutter analyze`（shell）— 验证结算和事件代码零错误
- **执行前需读取 Flutter Skills**：无

---

### Milestone 15：结局画面（Glitch 效果 + 报告）

- **目标**：实现两阶段结局演出（Glitch → Reveal）+ 生存报告统计
- **涉及文件**：
  - `lib/screens/ending_screen.dart` — 结局画面 Widget
  - `lib/widgets/glitch_text.dart` — Glitch 双色偏移文字（magenta + cyan offset）
  - `lib/widgets/survival_report.dart` — 生存报告卡片（Cycles / Code / Bugfix / Study 统计）
- **完成标准**：
  - Bad Ending: 先显示 `FATAL ERROR` + 随机 `CRASH_DUMP_` 地址（800ms），然后渐入 Reveal
  - Good/Normal Ending: 先显示 `COMPLETED` + `FINALIZING...`（400ms），然后渐入 Reveal
  - Reveal 阶段显示：结局标签图标（Skull/DoorOpen/Rocket/Bird/Crown）+ 标题 + 正文 + 统计报告
  - Bad Ending 背景：红色径向渐变；Good Ending 背景：绿色径向渐变
  - 显示 `[ RESTART ]` 按钮
  - RESTART 按钮点击后 → 清除存档 → 回到 TITLE 画面
  - 验证所有 5 种结局的文案与 `endings.json` 一致（含中文字符）
- **依赖**：M9, M14
- **需调用 Flutter MCP 执行的命令**：
  - `flutter analyze`（shell）— 验证 Glitch 动画代码零错误
- **执行前需读取 Flutter Skills**：无（Glitch 效果使用 Flutter 内置 AnimationController + Transform）

---

### Milestone 16：扩展系统集成（Modifier + Interruption + Pressure + Buff/Debuff + Streak + Spot Check）

- **目标**：将 6 个扩展子系统完整接入游戏循环
- **涉及文件**：
  - `lib/logic/modifier_resolver.dart` — `assignDayModifier()`, `applyModifierToDeltas()` 移植
  - `lib/logic/interruption_resolver.dart` — 打断事件抽取和效果应用
  - `lib/logic/pressure_resolver.dart` — `checkSuspicionPressure()` 移植
  - `lib/logic/status_evaluator.dart` — `computeActiveStatuses()`, `applyStatusToDeltas()` 移植
  - `lib/logic/streak_resolver.dart` — `getStreakAdjustedEffects()`, `checkSpotCheck()` 移植
  - `lib/widgets/buff_bar.dart` — Buff/Debuff 图标栏（32×32 方块、spring 弹入动画、tooltip）
  - `lib/state/game_notifier.dart` — 完整接入所有子系统
- **完成标准**：
  - 每日 OPENING 阶段 70% 概率分配 modifier，终端显示 modifier 信息
  - MORNING→AFTERNOON 有 25% 概率触发打断事件
  - suspicion ≥ 70 时晨间压力事件触发概率正确（30%~60% 线性增长）
  - 8 个 buff/debuff 状态在数值变化后自动评估，触发/消失时终端通知
  - ENERGIZED buff 仅当 energy ≥ 80 时激活（Patch-F04 上调后的阈值）
  - CORE_MEMBER buff 仅对 WRITE_CODE / FIX_BUG 生效
  - 连选惩罚 / 即时抓包正确触发，终端显示对应警告
  - BuffBar 组件正确渲染激活的状态图标
  - `flutter test` 扩展系统测试通过（≥ 30 个 test case，覆盖各子系统独立 + 交互场景）
- **依赖**：M14
- **需调用 Flutter MCP 执行的命令**：
  - `mcp__dart__run_tests` — 运行扩展子系统全套测试（≥30 case）
  - `flutter analyze`（shell）— 验证 6 个子系统集成代码零错误
- **执行前需读取 Flutter Skills**：
  - `flutter-add-widget-test` — 写 BuffBar 和弹窗 Widget 测试前读取

---

### Milestone 17：技能树 + 周度复盘

- **目标**：完整实现技能购买和 Day 7/14/21 周度复盘弹窗
- **涉及文件**：
  - `lib/widgets/week_review.dart` — 周度复盘全屏弹窗（数值总结 + 4 列技能树 + 购买交互 + SOCIAL_T2 特殊行动）
  - `lib/logic/skill_resolver.dart` — `applySkillToDeltas()` 移植
  - `lib/state/game_notifier.dart` — 完善 `earnSkillPoints()`, `purchaseSkill()`, `spendPointsForSuspicion()`
- **完成标准**：
  - Day 7 结算后，自动弹出 WeekReview 弹窗，显示"第一周回顾"
  - 成长点公式正确：Day 7 = 3 + kpi/30, Day 14 = 5 + kpi/25, Day 21 = 8 + kpi/20
  - 4 列技能树正确渲染（energy/tech/social/interview），每列 3 行（T1/T2/T3）
  - 已习得技能显示绿色 + Check 标记，可购买显示琥珀色虚线边框，锁定显示灰色 + Lock
  - 前置技能未解锁时不可购买
  - 购买成功后扣减成长点 + 终端通知 + 技能图标加入 Sidebar
  - ENERGY_T1 习得后 → 精力消耗 -10% 自动生效
  - TECH_T3 习得后 → `ARCH_REDESIGN` 出现在行动池中
  - SOCIAL_T2 习得后 → "请同事喝咖啡" 按钮可用（3pt → SUS -10）
  - 关闭弹窗后 → 正常进入下一天 OPENING
- **依赖**：M16
- **需调用 Flutter MCP 执行的命令**：
  - `flutter analyze`（shell）— 验证 WeekReview 弹窗代码零错误
  - `mcp__dart__run_tests` — 验证技能购买/解锁/效果应用逻辑
- **执行前需读取 Flutter Skills**：
  - `flutter-add-widget-test` — 写 WeekReview 弹窗交互测试前读取

---

### Milestone 18：音频系统

- **目标**：用 audioplayers 实现完整的 BGM 交叉淡入淡出 + SFX 按需播放 + 静音/音量控制
- **涉及文件**：
  - `lib/services/audio_manager.dart` — 单例：BGM crossfade (1s)、SFX 播放、音量/mute 同步、缺失文件静默降级
  - `lib/state/audio_notifier.dart` — 完善（已在 M3 创建骨架）
  - `lib/widgets/top_bar.dart` — 添加音量控制入口（BGM slider + SFX slider + 静音按钮）
- **完成标准**：
  - MORNING/AFTERNOON 阶段播放 `daily.mp3`（循环）
  - energy < 20 或 kpi < 20 时 crossfade 切换到 `tension.mp3`
  - EVENT 阶段保持当前 BGM
  - ENDING 阶段 BE → 停止 BGM + 播放 `glitch.mp3` SFX；GE/NE/HE → 播放 `ending-good.mp3`
  - 点击行动按钮时播放 `click.mp3` SFX
  - 静音开关实时生效；BGM 和 SFX 音量独立控制
  - 缺失音频文件时不崩溃，游戏正常运行（静默降级）
  - App 启动时无音频加载，首次行动触发 BGM 懒加载
- **依赖**：M13（首次交互后触发 BGM）
- **需调用 Flutter MCP 执行的命令**：
  - `flutter analyze`（shell）— 验证音频代码零错误
  - `mcp__dart__pub` — 若需添加音频依赖变更时使用
- **执行前需读取 Flutter Skills**：无（audioplayers 为标准 pub 包，无对应 Flutter skill）

---

### Milestone 19：视觉打磨（Glitch、数值动画、压力效果、动画转场）

- **目标**：将 Web 端所有动画和视觉特效在 Flutter 中还原
- **涉及文件**：
  - `lib/widgets/animated_number.dart` — `TweenAnimationBuilder<int>` 数值跳动动画（绿涨/红跌 + 变化量指示）
  - `lib/widgets/stress_fx.dart` — energy < 20 全屏红色内阴影脉冲
  - `lib/widgets/scanline_sweep.dart` — Sidebar 扫描线扫过动画
  - `lib/widgets/progress_bar.dart` — 进度条（霓虹填充 + 危险值闪烁 + 警告值脉冲）
  - `lib/widgets/neon_flicker.dart` — 霓虹文字闪烁组件
  - `lib/widgets/shake_widget.dart` — 高危事件抖动包装器
  - `lib/screens/ending_screen.dart` — 完善 Glitch 动画（`Transform.scale` + `clipRect` + `BackdropFilter`）
- **完成标准**：
  - 精力数值变化时：绿涨（↑ + numJumpUp）、红跌（↓ + numJumpDown）
  - 进度条 < 20: 红色 critical-flash 闪烁；< 40: 琥珀色 pulse 脉冲
  - energy < 20: 全屏红色 stress-fx 内阴影脉冲
  - Sidebar 扫描线扫过动画每 8s 循环一次
  - 高危事件弹出：0.6s 水平抖动
  - Glitch 结局：magenta + cyan 双色偏移 + clip-path 切割
  - `prefers-reduced-motion` 等价逻辑：提供全局动画开关
- **依赖**：M14, M15
- **需调用 Flutter MCP 执行的命令**：
  - `flutter analyze`（shell）— 最终全项目零错误验证
- **执行前需读取 Flutter Skills**：
  - `flutter-build-responsive-layout` — 打磨前再次读取，验证所有屏幕尺寸下的压力效果和动画不越界

---

### Milestone 20：集成测试 + 数值平衡验证

- **目标**：建立自动化测试套件，覆盖所有核心游戏循环和结局路径
- **涉及文件**：
  - `test/logic/endings_test.dart` — 结局判定全覆盖测试
  - `test/logic/events_test.dart` — 事件抽取统计测试
  - `test/logic/action_pool_test.dart` — 行动池抽取测试
  - `test/logic/game_loop_test.dart` — 状态机转换测试
  - `test/logic/clamp_test.dart` — clamp 边界测试
  - `test/state/game_notifier_test.dart` — Store action 集成测试
  - `test/data/data_integrity_test.dart` — 数据完整性测试
  - `integration_test/app_test.dart` — 端到端 UI 测试
- **完成标准**：
  - 单元测试 ≥ 150 个 case，全部通过
  - 集成测试覆盖：完整 30 天通关（HE_KING 路线）、BE_DEATH 触发、GE_OFFER 提前触发、Day 30 双重检查、存档 round-trip、版本不匹配丢弃
  - 数值平衡验证通过（同 Web 版 PRD §12.1 检查清单）：
    - 纯内卷路线（只 WRITE_CODE+FIX_BUG）→ Day 3-5 内精力耗尽
    - 平衡路线 → 可存活至 Day 30 触发 NE_PEACE
    - 跳槽路线（STUDY+SLACK）→ 约 7-10 天达成 interview ≥ 80
    - 所有数值在 [0, 100] 内，无一溢出
  - `flutter test` 和 `flutter test integration_test` 全部通过
- **依赖**：M1–M19
- **需调用 Flutter MCP 执行的命令**：
  - `mcp__dart__run_tests` — 运行全部单元测试 + 集成测试（≥150 case）
  - `flutter analyze`（shell）— 最终验证，确保全项目零错误
  - `mcp__dart__dart_format` — 全项目格式化
- **执行前需读取 Flutter Skills**：
  - `flutter-add-integration-test` — 写端到端测试前读取，了解 `integration_test` 包的用法
  - `flutter-add-widget-test` — 补充 Widget 级交互测试前读取

---

## 4. 风险与注意事项

### 4.1 状态一致性与 clamp 强制

- **风险**：Flutter 中无法像 Zustand 那样通过 TypeScript 类型系统强制所有状态更新走 clamp。开发者可能在某个 Widget 或 Notifier 方法中直接对字段赋值而绕过 clamp。
- **应对**：
  - `GameState` 中所有 4 个核心数值字段标记为 `@protected`（或使用 `freezed` 的不可变模型），强制所有修改必须通过 Notifier 中封装的方法
  - 在 `GameNotifier` 的每个修改方法内部，统一调用 `_clamp()` 私有方法
  - CI 中增加 lint 规则，禁止直接对 GameState 字段赋值

### 4.2 SETTLEMENT 同步执行保证

- **风险**：Web 端通过 Zustand 的同步 `set()` 调用保证 SETTLEMENT 逻辑在一个同步块中完成。Flutter 中若分散到多个 `setState`（或 Riverpod 的多次 `state =`），可能出现中间状态被 UI 捕获，导致闪现不完整画面。
- **应对**：
  - `runSettlement()` 内部计算全部在局部变量中完成，最后一次性 `state = newState` 写入
  - 函数内部不调用其他可能触发 UI 重建的 Notifier 方法

### 4.3 中文文本渲染

- **风险**：Flutter 在 Android 上默认可能缺少中文字体，导致游戏内大量中文内容（开场白、事件描述、日志）显示为方块。
- **应对**：
  - 在 `pubspec.yaml` 中显式声明中文字体回退（如 `NotoSansSC`），或使用 Google Fonts 的 `NotoSansSC` 包
  - M10 (赛博朋克视觉基础) 中作为首要验证项：确保"降本增效"等中文文本正确渲染
  - 所有字体配置在 `ThemeData.textTheme` 中统一设置

### 4.4 Matrix 数字雨性能

- **风险**：Web 端 Matrix 雨用 Canvas + `setInterval(50ms)` 实现。Flutter 中若用 `CustomPainter` + 频繁 `repaint`，可能会造成 Android 设备上帧率下降和电池消耗。
- **应对**：
  - 使用 `AnimationController`（而非 Timer）驱动重绘，确保与屏幕刷新率同步
  - 减少列数（低端设备自动检测屏幕宽度/14 而非固定 14px 字体）
  - 使用 `RepaintBoundary` 隔离 Canvas 重绘区域
  - 限制拖尾长度为 6 个字符（而非 Web 版的 8 个）

### 4.5 音频 crossfade 精度

- **风险**：Howler.js 的 `fade()` 是内置 API。audioplayers 无此功能，手动 Timer 实现的 crossfade 可能不够平滑，存在爆音或音量跳跃。
- **应对**：
  - 使用 50ms 间隔（而非 100ms）逐步调整音量，共 20 步
  - 在 crossfade 期间用一个独立的 `AudioPlayer` 实例播放新 BGM，旧 BGM volume 递减至 0 后 stop + dispose
  - 每个 BGM 场景映射一个 `AudioPlayer`，避免资源泄漏

### 4.6 JSON 数据文件路径差异

- **风险**：Web 版用 `import` 直接导入 JSON（Next.js 支持）。Flutter 用 `rootBundle.loadString()` + `jsonDecode()`，路径格式和加载方式完全不同。所有 `fromJson` 需要显式编写。
- **应对**：
  - M2 中所有模型类手写 `fromJson` 工厂构造函数（或用 `freezed` + `json_serializable` 自动生成）
  - M7 中统一通过 `GameData` 门面加载，避免散落各处的 `rootBundle.loadString()` 调用
  - CI 中增加数据完整性检查：加载所有 JSON 文件后逐字段验证类型和值域

### 4.7 存档格式兼容性

- **风险**：若未来 Web 版和 Flutter 版数据结构不同，或版本升级修改了 GameState 字段，存档可能不可逆损坏。
- **应对**：
  - Flutter 版沿用相同 `version` 字段和 `frontend-survival-save` key
  - 存档增加 schema version 独立于游戏版本（如 `schemaVersion: 1`），确保向后兼容
  - M9 存档系统中实现：`version` 不匹配 → 丢弃；`schemaVersion` 大版本不匹配 → 丢弃；小版本不匹配 → 迁移
  - 记录每次 GameState 字段变更到 `MIGRATION_LOG.md`

### 4.8 TypeScript vs Dart 类型差异

- **风险**：TS 中 `Record<string, number>`、联合类型 `'INFO' | 'WARNING' | ...`、可选字段 `?`、索引签名等在 Dart 中表达方式不同。
- **应对**：
  - 联合类型 → Dart `enum`
  - `Record<string, number>` → `Map<String, int>`
  - 可选字段 → Dart `?`（nullable）或提供默认值
  - TS `Pick<>` / `Partial<>` → 手写对应的 Dart 类或使用 `freezed` 的 `copyWith`

### 4.9 测试覆盖率与回归防护

- **风险**：迁移过程中可能引入数值计算偏差（如 clamp 未生效、优先级顺序错误），手动测试难以全面覆盖。
- **应对**：
  - 每个 Milestone 锁定后立即编写对应的单元测试
  - M20 集成测试作为最终把关，覆盖所有 5 种结局 + 关键边界条件
  - 设置最低覆盖率目标：`lib/logic/` 100%，`lib/state/` ≥ 90%

---

## 5. 目录结构规划

```
frontend_survival/           # Flutter 项目根目录
├── pubspec.yaml
├── lib/
│   ├── main.dart            # App 入口
│   ├── app.dart             # MaterialApp + GoRouter 配置
│   ├── state/
│   │   ├── game_notifier.dart   # GameNotifier (≈useGameStore)
│   │   ├── audio_notifier.dart  # AudioNotifier (≈useAudioStore)
│   │   └── providers.dart       # Provider 导出
│   ├── models/
│   │   ├── game_state.dart
│   │   ├── action_def.dart
│   │   ├── action_stats.dart
│   │   ├── day_modifier.dart
│   │   ├── ending_type.dart     # enums: EndingType, GamePhase, LogType
│   │   ├── game_event.dart
│   │   ├── interruption.dart
│   │   ├── log_entry.dart
│   │   ├── pressure_event.dart
│   │   ├── skill_def.dart
│   │   └── status_condition.dart
│   ├── logic/
│   │   ├── action_pool.dart     # sampleActionPool()
│   │   ├── action_resolver.dart # 效果修正链
│   │   ├── endings.dart         # checkDailyEnding, checkFinalEnding
│   │   ├── events.dart          # sampleEvent()
│   │   ├── game_loop.dart       # isValidTransition, getNextPhase
│   │   ├── modifier_resolver.dart
│   │   ├── interruption_resolver.dart
│   │   ├── pressure_resolver.dart
│   │   ├── status_evaluator.dart
│   │   ├── streak_resolver.dart
│   │   └── skill_resolver.dart
│   ├── data/
│   │   └── game_data.dart       # 统一数据加载门面
│   ├── services/
│   │   ├── audio_manager.dart   # audioplayers 单例
│   │   └── save_service.dart    # SharedPreferences 封装
│   ├── theme/
│   │   ├── app_theme.dart       # ThemeData
│   │   ├── colors.dart          # 色板常量
│   │   ├── typography.dart      # 字体配置
│   │   └── neon_styles.dart     # NeonTextStyle, GlowBoxDecoration
│   ├── screens/
│   │   ├── game_screen.dart     # 主游戏画面（IDE 布局）
│   │   ├── title_screen.dart    # 标题画面
│   │   └── ending_screen.dart   # 结局画面
│   ├── widgets/
│   │   ├── crt_overlay.dart     # CRT 扫描线
│   │   ├── matrix_rain.dart     # Matrix 数字雨
│   │   ├── ascii_title.dart     # ASCII Art 标题
│   │   ├── glow_text.dart       # 霓虹发光文字
│   │   ├── cyber_button.dart    # 赛博朋克按钮
│   │   ├── top_bar.dart         # 顶栏 HUD
│   │   ├── sidebar.dart         # 侧栏面板
│   │   ├── editor.dart          # 中央内容区
│   │   ├── terminal_widget.dart # 终端日志
│   │   ├── event_dialog.dart    # 事件弹窗
│   │   ├── buff_bar.dart        # Buff/Debuff 图标栏
│   │   ├── week_review.dart     # 周度复盘弹窗
│   │   ├── typewriter_text.dart # 打字机文字
│   │   ├── animated_number.dart # 数值动画
│   │   ├── progress_bar.dart    # 霓虹进度条
│   │   ├── action_button.dart   # 行动按钮
│   │   ├── action_grid.dart     # 行动网格
│   │   ├── glitch_text.dart     # Glitch 效果文字
│   │   ├── survival_report.dart # 结局报告卡片
│   │   ├── stress_fx.dart       # 压力视觉效果
│   │   ├── shake_widget.dart    # 抖动包装器
│   │   └── neon_flicker.dart    # 霓虹闪烁
│   └── utils/
│       ├── clamp.dart           # clamp()
│       └── weekend.dart         # isWeekend()
├── assets/
│   ├── data/                    # 10 个 JSON 文件
│   ├── backgrounds/             # 7 个 PNG 文件
│   └── audio/
│       ├── bgm/                 # BGM MP3 文件
│       └── sfx/                 # SFX MP3 文件
├── test/                        # 单元测试
│   ├── logic/
│   │   ├── endings_test.dart
│   │   ├── events_test.dart
│   │   ├── action_pool_test.dart
│   │   ├── game_loop_test.dart
│   │   └── clamp_test.dart
│   ├── state/
│   │   └── game_notifier_test.dart
│   └── data/
│       └── data_integrity_test.dart
└── integration_test/
    └── app_test.dart
```

---

## 附录 A：关键算法伪代码引用

所有算法实现必须严格对齐以下 TECH_ARCH 定义：

- **clamp**: `Math.max(0, Math.min(100, val))` → `val.clamp(0, 100)`
- **checkDailyEnding**: TECH_ARCH §4.1（3 步优先级检查）
- **checkFinalEnding**: TECH_ARCH §4.2（4 步优先级检查，含 Patch-011 BE_FIRED 兜底）
- **sampleEvent**: TECH_ARCH §5.1（4 步：空事件 → 过滤 → 权重调整 → 加权随机）
- **sampleActionPool**: TECH_ARCH §6.1（≥2 核心 + ≥1 休息 + ≥1 工作）
- **SETTLEMENT flow**: AGENTS.md §4.3（5 步顺序：drain → daily → final → ending 或 day++）

## 附录 B：数据文件字段校验清单

每个 JSON 文件迁移后必须验证：

| 文件 | 验证项 |
|------|--------|
| `actions.json` | 12 个 ActionDef，每个含 id/label/effects/prerequisite/log/core/condition |
| `events.json` | 65 个 GameEvent，每个含 id/title/description/weight/highRisk?/condition/options[2]；QTE 事件额外含 qteConfig |
| `openings.json` | 30 个 key (string "1"~"30")，每个为 string |
| `endings.json` | 5 个 key (BE_DEATH/BE_FIRED/GE_OFFER/NE_PEACE/HE_KING) |
| `modifiers.json` | 12 个 DayModifier，每个含 id/label/description/effects/weight |
| `interruptions.json` | 8 个 Interruption，每个含 id/title/description/effects/log |
| `pressure-events.json` | 6 个 PressureEvent，每个含 id/title/description/effects/log/minSuspicion/weight |
| `status-conditions.json` | 8 个 StatusCondition，每个含 id/name/type/priority/triggers[]/effects/icon/tooltip |
| `skills.json` | 12 个 SkillDef，每个含 id/name/branch/tier/cost/requires/effects/icon/description |
| `event-categories.json` | 4 个分类，每个含 label/background/events[] |

---

## Current Implementation Reconciliation (2026-05-30)

This migration plan is historical. For current implementation facts, Patch-F18 in `DOC_AUDIT.md` and the section below supersede older milestone notes.

- Migration to Flutter/Android is complete.
- Current app label is `Frontend Survival`; launcher icons are generated from `tmp_icon/icon.png`.
- Current data scale is 12 actions, 65 events, 14 high-risk events, 5 QTE events, 10 JSON data files, and 8 background PNGs.
- Current automated validation is `flutter analyze` with zero issues and `flutter test` with 248 passing tests across 15 Dart files.
- Current save system is SharedPreferences key `frontend-survival-save`.
- Current audio system uses 3 BGM mp3 files and 5 SFX files (`ogg`/`wav`).
