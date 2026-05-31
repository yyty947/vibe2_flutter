> **摘要 (Abstract)**: 本文档为《前端生死劫》Flutter 版提供视觉语言与组件样式标准。核心视觉风格为**赛博朋克终端 (Cyberpunk Terminal)**，使用深黑背景 + 霓虹发光效果，营造高压科幻氛围。文档定义了布局比例、颜色语义及关键反馈动画，确保 AI 生成的 UI 具有强烈的终端工具感与沉浸式赛博朋克美学。
>
> **Flutter 版适配**: 原 Web 版 CSS 类名（`.neon-green`, `.glow-box-red` 等）已映射为 Dart 常量和方法（`AppColors.neonGreen`, `NeonStyles.green()`）。`@keyframes` CSS 动画已迁移为 `AnimationController` + `Tween`。布局从 Tailwind 工具类迁移为 `LayoutBuilder` + `Expanded`/`Flexible`。

---

## 1. 设计原则 (Design Principles)

- **终端化 (Terminal-like)**: 界面应看起来像一个科幻终端/HUD，而非传统 IDE 或游戏界面。
- **霓虹高对比 (Neon Contrast)**: 深黑背景 `#0D0D0D` 搭配霓虹发光色（绿/青/红/琥珀），模拟 CRT 显示器。
- **信息密度 (Density)**: 信息展示应紧凑有序，HUD 风格面板展示关键指标。
- **无 Emoji 图标 (No Emojis)**: 所有图标使用 `lucide_icons` 包（`LucideIcons.*`），禁止在 UI 中使用 emoji 作为功能图标。

## 2. 核心色板 (Color Palette)

颜色常量定义于 `lib/theme/colors.dart` → `AppColors` 类。

### 2.1 背景层级
- **Deep Background**: `AppColors.bgDeep` (`#0D0D0D`) — 主背景
- **Panel**: `AppColors.bgPanel` (`#111116`) — 面板/Sidebar/TopBar 背景
- **Surface**: `AppColors.bgSurface` (`#18181F`) — 按钮/卡片/输入框背景
- **Elevated**: `AppColors.bgElevated` (`#1E1E28`) — Hover 状态背景

### 2.2 霓虹语义色
- **Primary/Success**: `AppColors.neonGreen` (`#00FF9F`) — 正面效果、健康状态、成功
- **Info/Tech**: `AppColors.neonCyan` (`#00FFFF`) — 技术信息、面试相关
- **Warning**: `AppColors.neonAmber` (`#FFB800`) — 警告、中等风险、怀疑度
- **Danger**: `AppColors.neonRed` (`#FF0040`) — 危险、低数值、高危事件
- **Accent**: `AppColors.neonMagenta` (`#FF0080`) — Glitch 特效、强调

### 2.3 文字层级
- **Primary Text**: `AppColors.textPrimary` (`#E0E0E0`)
- **Muted Text**: `AppColors.textMuted` (`#666680`)
- **Dim Text**: `AppColors.textDim` (`#444444`)

### 2.4 边框
- **Standard**: `AppColors.borderDim` (`#2A2A35`)
- **Glow**: 配合霓虹色使用 `.withAlpha()` 方法（如 `AppColors.neonGreen.withAlpha(100)`）

## 3. 字体 (Typography)

字体样式定义于 `lib/theme/typography.dart` → `AppFonts` 类。

- **HUD/标题字体**: Share Tech Mono — `AppFonts.hud(size)` / `AppFonts.hudFamily`
- **代码/正文字体**: Fira Code — `AppFonts.code(size)` / `AppFonts.codeFamily`
- 全局等宽字体，通过 `google_fonts` 包加载

## 4. 布局定义 (Layout Specification)

布局实现于 `lib/screens/game_screen.dart`。**方向**: 横屏锁定（`SystemChrome.setPreferredOrientations(landscapeLeft/Right)`）。

**三层垂直结构**:

- **Top Bar (h=28)**: `lib/widgets/top_bar.dart` — `Container(height: 28)` + `Row`。展示：`LucideIcons.terminal` 图标、`FRONTEND SURVIVAL` 标题、`CYCLE N / 30`、当前相位、静音按钮、重启按钮
- **中部三列（最大高度）**:
  - **左列 (72dp)**: `lib/widgets/sidebar.dart` → `LeftDatePanel` — 圆形天数 + `/30` + 30天时间线（4点/行，共8行），已过=淡绿，当前=亮绿，未来=暗灰
  - **中列 (Expanded)**: `lib/widgets/editor.dart` — 各相位内容（开场白/行动按钮2×2/事件弹窗/结算动画）
  - **右列 (150dp)**: `lib/widgets/sidebar.dart` → `RightStatsPanel` — 四项属性竖排（图标+标签+进度条+数值）+ 分割线 + Buff/Debuff 点击弹出 Tooltip + 成长点余额（始终显示）+ 已习得技能标签 + 相位标签
- **底部 Terminal (可折叠, 72px)**: `lib/widgets/terminal_widget.dart` — 折叠/展开按钮 + 霓虹日志列表

**布局结构**:
```
┌──────────────────────────────────────────────────────────────┐
│ TopBar (h=28): [icon] TITLE | CYCLE N/30 | PHASE | 静音 | 重启 │
├──────┬───────────────────────────────────────┬───────────────┤
│ DAY  │                                       │ ENR  ████  80 │
│  05  │                                       │ KPI  ████  55 │
│ /30  │           Editor (Expanded)            │ INT  ████  30 │
│      │                                       │ SUS  ████  25 │
│  ··  │                                       │               │
│  ··  │                                       │ [BUFF 芯片]   │
│  ··  │                                       │ [PHASE 标签]  │
├──────┴───────────────────────────────────────┴───────────────┤
│ TERMINAL ▼  (可折叠, 收起时只显示标题栏)                      │
└──────────────────────────────────────────────────────────────┘
```

## 5. 组件规范 (Component Specs)

### 5.1 进度条 (Progress Bars)
实现于 `lib/widgets/sidebar.dart` → `_RightStat`（右侧属性面板）和 `_StatBar`（已废弃）。
- 底色: `Color(0xFF1A1A24)`
- 填充色: `LinearProgressIndicator(value: stat/100, valueColor: barColor)`
- 危险值 (<20): `AppColors.neonRed`
- 警告值 (<40): `AppColors.neonAmber`
- 优秀值 (>80): `AppColors.neonGreen`（SUSPICION 属性反向：≥80 红色，≥60 琥珀）

### 5.2 行动按钮 (Action Buttons)
实现于 `lib/widgets/editor.dart` → `_ActionCard`。
- 2×2 或 3 列 GridView（通过 `sampleActionPool()` 动态决定）
- 效果缩写: ENR（精力）、KPI（绩效）、INT（面试度）、SUS（怀疑度）
- 颜色按 actionId 映射（WRITE_CODE=绿, FIX_BUG=琥珀, STUDY=青, SLACK/ALLIANCE=品红）
- 禁用: 低透明度 + 灰色文字 + `ENERGY LOW` 标记
- 连选角标: 右上角 `Positioned` 红色/琥珀色圆角容器 ×N

### 5.3 事件对话框 (Event Dialog)
实现于 `lib/widgets/editor.dart` → `EventContent`。
- 普通事件: 青色边框 + `LucideIcons.alertTriangle`
- 高危事件: 红色边框 + `LucideIcons.shieldAlert` + `BoxShadow` 红色发光
- 选项效果使用霓虹色标注（正面绿色、负面红色）

### 5.4 终端日志 (Terminal Logs)
实现于 `lib/widgets/terminal_widget.dart` → `TerminalWidget`。
- 前缀格式: `[D##] [TYPE]`（使用 `TextSpan` 构建 `Text.rich`）
- 日志类型颜色映射（通过 `_logColor()` 方法）:
  - `COMMIT`: `AppColors.neonGreen`
  - `BUGFIX`: `AppColors.neonCyan`
  - `WARNING`: `AppColors.neonAmber`
  - `ALERT`: `AppColors.neonRed`
  - `INFO/SLACK`: `AppColors.textMuted`
- 头部显示 `System Log // Output_Channel_0` + 伪标签

### 5.5 Sidebar (HUD 面板)
实现于 `lib/widgets/sidebar.dart` → `Sidebar`。
- 图标: `LucideIcons.zap`(精力), `LucideIcons.trendingUp`(绩效), `LucideIcons.target`(面试), `LucideIcons.eye`(怀疑)
- 数值动画: `lib/widgets/animated_number.dart` → `AnimatedNumber`（弹跳 + 颜色闪烁）
- 状态评估: `NOMINAL` / `WARNING` / `CRITICAL`（根据 energy 值）
- BuffBar: `lib/widgets/buff_bar.dart` → `BuffBar`（28×28 方块 + Tooltip）
- 时间线: 7×5 `Wrap` 网格，已过/当前/未来用不同颜色区分

### 5.6 标题画面 (Title Screen)
实现于 `lib/screens/title_screen.dart` → `TitleScreen`。
- Matrix 数字雨: `lib/widgets/matrix_rain.dart` → `MatrixRain`（`CustomPainter` + `AnimationController.repeat()`）
- ASCII Art 标题: `_AsciiTitle`（`TweenAnimationBuilder` 霓虹闪烁）
- 终端风格副标题: `$` 前缀绿色文字
- 霓虹按钮: `[ NEW GAME ]` / `[ CONTINUE ]` — `_CyberButton` 组件
- 存档检测: 异步调用 `SaveService.hasSave()`

### 5.7 结局画面 (Ending Screen)
实现于 `lib/screens/ending_screen.dart` → `EndingScreen`。
- **两阶段演出**:
  1. Glitch 阶段: `_GlitchPhase` — magenta + cyan 双色 `Shadow` + `CRASH_DUMP_` 随机地址
  2. Reveal 阶段: `_RevealPhase` — 渐入结局标题/正文 + 生存报告 + `[ RESTART ]`
- 结局图标: `LucideIcons.skull`(BE_DEATH), `LucideIcons.doorOpen`(BE_FIRED), `LucideIcons.rocket`(GE_OFFER), `LucideIcons.checkCircle`(NE_PEACE), `LucideIcons.crown`(HE_KING)
- 背景氛围: Bad Ending `RadialGradient` 红色，Good Ending 绿色

## 6. 动画与特效 (Vibe & Feedback)

各特效独立封装为可复用 Widget：

| 特效 | 实现文件 | Flutter 方案 |
|------|---------|-------------|
| **Matrix 数字雨** | `lib/widgets/matrix_rain.dart` | `AnimationController.repeat(50ms)` + `CustomPainter` |
| **霓虹闪烁** | `lib/screens/title_screen.dart` → `_AsciiTitle` | `TweenAnimationBuilder(opacity)` 3s 周期 |
| **Glitch 双色** | `lib/screens/ending_screen.dart` → `_GlitchPhase` | `TextStyle.shadows` magenta + cyan offset |
| **打字机效果** | `lib/widgets/typewriter_text.dart` | `Timer.periodic(30ms)` + `FadeTransition` 光标闪烁 |
| **压力视觉 (Stress FX)** | `lib/widgets/stress_fx.dart` | `AnimationController.repeat(1500ms)` + `BoxShadow` 红色内阴影脉冲 |
| **数值动画** | `lib/widgets/animated_number.dart` | `AnimationController(400ms)` + `TweenSequence` 弹跳 + `Color.lerp` 颜色闪烁 |
| **抖动 (Shake)** | `lib/widgets/shake_widget.dart` | `AnimationController(600ms)` + `TweenSequence` 水平平移 |
| **打字机日志** | `lib/widgets/typewriter_text.dart` | `TypewriterText` Widget 复用 |

### 6.1 过渡动画系统 (Transition System)

统一时长 **300ms**，`Curves.easeOut` 默认缓动。

| 动画 | 实现 | 方案 |
|------|------|------|
| **相位切换** | `lib/widgets/editor.dart` → `Editor.build()` | `AnimatedSwitcher(300ms)` + `transitionBuilder` → `ScaleTransition(0.9↔1.0)` + `FadeTransition`（进入+退出双向） |
| **弹窗弹出** | `lib/widgets/editor.dart` → `_PopIn` | 延迟 300ms 后 scale 0.9→1.0 + fade，300ms |
| **背景交叉淡入淡出** | `lib/widgets/editor.dart` → `Editor.build()` | `AnimatedSwitcher(500ms, ValueKey(bgPath))` — 8张图预加载 |
| **行动卡片弹出** | `lib/widgets/editor.dart` → `ActionContent` | `_PopIn(delayMs: 500)` — 背景先换，0.5s 后卡片浮现 |
| **结算加载圈** | `lib/widgets/editor.dart` → `SettlementContent` | `TweenAnimationBuilder` fade-in (300ms) |
| **Buff/技能弹性入场** | `lib/widgets/sidebar.dart` | `TweenAnimationBuilder(Curves.elasticOut, 350ms)` scale 0→1 |
| **终端日志滑入** | `lib/widgets/terminal_widget.dart` | `TweenAnimationBuilder` slide-up + fade (300ms) |
| **终端折叠/展开** | `lib/screens/game_screen.dart` | `AnimatedSize(250ms, easeOut)` |
| **周度复盘面板** | `lib/widgets/week_review.dart` | `TweenAnimationBuilder` scale+fade (300ms) |

### 6.2 毛玻璃规范 (Glassmorphism Spec)

`lib/widgets/editor.dart` → `GlassPanel`：

```
RepaintBoundary → ClipRRect(borderRadius) → BackdropFilter(sigma=12) → Container(bg alpha=0.4, border white alpha=0.1) → child
```

- `RepaintBoundary` 防止触摸/滑动时 BackdropFilter 被丢弃
- `_PopIn` 的 `Opacity` 使用 `0.01 + 0.99 * value`，确保 BackdropFilter 图层永不消失
- 应用面板：Opening、Action Cards、Event、Interruption、Pressure

### 6.3 按压缩放+触觉反馈 (Press-Scale & Haptic)

所有交互按钮：

```
AnimatedScale(0.93/0.95/0.97, 100ms, easeInOutCubic) → GestureDetector(onTapDown/onTapUp/onTapCancel) → 内容
```

`onTapDown` → `HapticFeedback.lightImpact()` (线性马达轻触)

| 组件 | 缩放比 | 延迟 |
|------|--------|------|
| 行动卡片 | 0.95 | onTap 150ms |
| 事件选项 | 0.97 | onTap 150ms |
| 打断/高压按钮 | 0.93 | 无 |
| 技能节点 | 0.93 | 无 |
| 周度按钮 | 0.93 | 无 |

### 6.4 Overscroll 防护

所有滚动组件使用 `ClampingScrollPhysics()` + `ScrollConfiguration(overscroll: false)`，防止 overscroll 击穿 BackdropFilter。

### 6.5 状态面板视觉 (Stat Panel Visuals)

- **呼吸闪烁**：`AnimationController.repeat(reverse: true)` — 警告 1.5s 周期，危险 0.7s 周期
- **阈值颜色**：ENERGY/KPI ≤20 黄色、≤10 红色；SUSPICION ≥70 红色呼吸、≥85 红色发光
- **INTERVIEW** 不触发任何特效，始终黄色
- **SUSPICION** 基础色始终红色
- **进度条过渡**：`TweenAnimationBuilder(400ms)` 平滑宽度+颜色
- **浮动飘字**：`_FloatingDeltaText` — 数值变化时 delta 上浮+渐隐 (700ms)

## 7. AI 指令补丁 (AI Style Patch)

- 优先使用 `Row` / `Column` + `Expanded` / `Flexible` 布局
- 所有可交互元素必须有 `GestureDetector`，使用 `AnimatedScale` + `HapticFeedback.lightImpact()` 提供物理反馈
- 所有图标必须使用 `lucide_icons` 包（`LucideIcons.*`），禁止 emoji
- 毛玻璃面板必须使用 `GlassPanel` 组件，不得手动拼接 `ClipRRect → BackdropFilter → Container`
- 所有滚动组件必须设置 `ClampingScrollPhysics()` + `overscroll: false`
- `BackdropFilter` 祖先链中不得使用 `Opacity(opacity: 0)`，必须用 `0.01 + 0.99 * value`
- `GlassPanel` 最外层必须有 `RepaintBoundary`
- 霓虹色文字使用 `AppColors.neonGreen` 等常量，发光文字使用 `NeonStyles.green(size)`
- 发光边框使用 `NeonStyles.glowBoxGreen()` 等方法
- 进度条使用 `LinearProgressIndicator` + `AlwaysStoppedAnimation(barColor)`
- 字体使用 `AppFonts.hud()` / `AppFonts.code()` 或 `TextStyle(fontFamily: AppFonts.hudFamily)`
- 纯 UI 组件使用 `ConsumerWidget` 读取状态；不包含业务逻辑

---

## Current Implementation Reconciliation (2026-05-30)

This section is authoritative for current Flutter UI behavior and supersedes stale component names or counts elsewhere in this design document.

- Launcher label is `Frontend Survival`; the title/HUD brand remains Frontend Survival.
- The shared glass widget is `GlassPanel` in `lib/widgets/editor.dart`, not `_GlassPanel`. It uses `RepaintBoundary`, blur sigma 12, and themed `glassOverlay`/`glassBorder`.
- The active action card widget is `_ActionCard`, not `_ActionTile`.
- The active HUD buff/debuff display is `_RightBuffBar` in `lib/widgets/sidebar.dart`; `lib/widgets/buff_bar.dart` is retained legacy code.
- Background crossfade uses 8 preloaded PNG assets, including `QTE.png`.
- QTE events render the QTE game surface with `assets/backgrounds/QTE.png`; the surrounding event/background layer can still use the normal phase/category background.
- Ending copy is data-driven from `assets/data/endings.json`; `EndingScreen` keeps only visual tags, colors, and icons in code.
- NE_PEACE currently uses `LucideIcons.checkCircle` in the ending reveal.
