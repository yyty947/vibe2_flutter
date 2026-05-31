# ONBOARDING.md - AI 接手指南

你正在接手一个已经完成多轮迭代的 Flutter Android 游戏项目。先读文档，再改代码；当前最新对齐记录见 `docs/DOC_AUDIT.md` Patch-F18。

## 1. 必读顺序

| 顺序 | 文件 | 作用 |
|------|------|------|
| 1 | `docs/DOC_AUDIT.md` | 补丁层和冲突裁决；Patch-F18 记录当前实现事实 |
| 2 | `docs/PRD.md` | 产品规则、核心玩法、结局条件 |
| 3 | `docs/TECH_ARCH.md` | 状态模型、状态机、算法、存档、音频、QTE |
| 4 | `docs/UI_DESIGN_SYSTEM.md` | 横屏 HUD、主题、动效、组件样式 |
| 5 | `docs/GAME_CONTENT.md` | 静态数据 schema 和数据规模 |
| 6 | `AGENTS.md` | 代码代理必须遵守的执行规则 |
| 7 | `TESTING_GUIDE.md` | 当前测试结构和验证命令 |

## 2. 当前实现快照

- 平台：Flutter Android，横屏锁定，纯客户端，无后端和账号。
- 启动器名称：`Frontend Survival`。
- 版本：`pubspec.yaml` 为 `1.3.0+1`；存档版本为 `GameState.gameVersion == 1.3.0`。
- 存档：`SharedPreferences`，固定 key `frontend-survival-save`。
- 数据：`GameData.init()` 加载 10 个 JSON 文件，预加载 8 张背景图。
- 玩法内容：12 个行动、65 个事件、14 个高危事件、5 个 QTE 事件、8 个状态条件、12 个技能、12 个日间修饰符、8 个打断事件、6 个压力事件。
- 测试：248 个自动化测试，分布在 15 个 Dart 测试文件中。

## 3. 代码结构速览

| 路径 | 当前职责 |
|------|----------|
| `lib/state/game_notifier.dart` | `GameState` 的 Riverpod Notifier，处理所有游戏动作、状态流转、QTE 结算和辅助测试入口 |
| `lib/state/audio_notifier.dart` | 音频设置状态，不写入存档 |
| `lib/state/theme_provider.dart` | `GameTheme.compute()`，从 `GameState` 纯派生 Dark/Light/Danger 主题 |
| `lib/models/game_state.dart` | 24 字段状态模型，含 sentinel `copyWith` 和 JSON 序列化 |
| `lib/logic/` | 纯逻辑：状态机、结局、事件抽样、行动池、行动效果链、状态条件 |
| `lib/data/game_data.dart` | 同步数据门面；启动时加载 JSON 和背景资源 |
| `lib/services/save_service.dart` | SharedPreferences 存档读写、版本检查和清除 |
| `lib/services/audio_manager.dart` | audioplayers 单例，BGM crossfade 与 SFX 播放 |
| `lib/screens/` | Title/Game/Tutorial/Ending/VideoIntro 等全屏页面 |
| `lib/widgets/` | HUD、Editor、Terminal、QTE、技能树、动效组件 |
| `assets/data/` | 游戏静态内容源；不要在 Widget/logic 中硬编码叙事文案 |
| `assets/backgrounds/` | 8 张背景 PNG，包括 `QTE.png` |

## 4. 关键运行行为

- NEW GAME 先进入开场视频；CONTINUE 不播放视频，直接从存档进入 `OPENING`。
- `startNewGame()` 会立即评估状态条件；初始 suspicion=20 会激活 `TRUSTED`，并写入一条状态日志。
- 每天流程是 `OPENING -> MORNING -> AFTERNOON -> EVENT -> SETTLEMENT`；无结局时回到下一天 `OPENING`。
- Day 30 结算顺序固定：energy -5，先跑 daily ending，再在 daily 没触发时跑 final ending。
- 无结局存档由 `GameScreen` 在下一天 `OPENING` post-frame 触发；结局存档清理由 `EndingScreen` 在 glitch/reveal 动画结束后触发。
- QTE 固定日为 Day 5/10/15/20/25；周复盘日为 Day 7/14/21，目前没有重叠冲突日。
- QTE 事件 JSON 仍保留两个 `options` 以满足 parser/schema；实际 QTE 结果数值来自 `qteConfig`。

## 5. UI 要点

- 主布局：`TopBar(28) + Row(LeftDatePanel 72 | Editor expanded | RightStatsPanel 150) + CollapsibleTerminal`。
- 毛玻璃组件是 `GlassPanel`，位于 `lib/widgets/editor.dart`；必须保留 `RepaintBoundary`、sigma=12、主题化 overlay/border。
- 当前 Buff/Debuff HUD 是 `sidebar.dart` 内的 `_RightBuffBar`；`lib/widgets/buff_bar.dart` 是保留的旧组件。
- 行动卡是 `_ActionCard`；事件选项是 `_EventOption`；按钮使用按压缩放和触觉反馈。
- 主题不能手动切换，只能由 `GameTheme.compute()` 从 `GameState` 派生。

## 6. 常用命令

```powershell
flutter analyze
flutter test
flutter run -d <device_id>
flutter build apk --release
```

当前验证基线：`flutter analyze` 无问题，`flutter test` 248 个测试全通过。

## 7. 硬约束

- 修改 runtime code 前必须读 `DOC_AUDIT`、相关 PRD 和相关 TECH_ARCH。
- 所有 `energy/kpi/interview/suspicion` 写入必须经过 `clamp()`。
- 结局检查只允许发生在 `SETTLEMENT`。
- 不要在 UI 或逻辑层硬编码事件、开场白、行动效果、结局正文。
- 不要新增 Riverpod Notifier 或运行时依赖，除非有清晰必要性并更新文档。
- 不要绕过 `SaveService`、`AudioManager` 或现有数据模型。
