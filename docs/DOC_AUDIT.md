# 文档审计与勘误 (DOC_AUDIT.md)



> **摘要 (Abstract)**: 本文档是《前端生死劫》项目的"动态补丁库"。在开发过程中，如果出现 PRD 遗漏、临时需求变更或文档间的规则冲突，所有最终结论必须记录于此。**AI 在执行任何代码生成任务前，必须优先读取本文档的【Active Patches】部分，本文档的��先级高于所有其他文档。**



---



## 1. 审计规则 (Audit Rules)

- 禁止随意修改 `PRD.md` 的原始设定。
- 任何通过对话临时增加的设定，必须以"Patch"的形式追加到本文件。
- 已经被废弃或解决的冲突，移至"Resolved"区域。



## 2. 活跃补丁 (Active Patches & Overrides)

### Patch-001 [2026-04-18] 文档交叉引用修复（已落地）

**冲突**：PRD 1.4 和 TECH_ARCH 引用了 `GAME_DATA.md`、`API_INTERFACE.md`、`DATA_TEMPLATES.md` 三个不存在的文件。实际文件名为 `GAME_CONTENT.md`。

**处理**：
- PRD 1.4 索引表已修正为实际存在的 4 份文档（DOC_AUDIT / TECH_ARCH / UI_DESIGN_SYSTEM / GAME_CONTENT）。
- PRD 文末引用已移除 `API_INTERFACE.md`。
- TECH_ARCH 中 `GAME_DATA.md` 引用已替换为 `GAME_CONTENT.md`。

---

### Patch-002 [2026-04-18] 状态机相位补全（已落地）

**冲突**：原 TECH_ARCH 的 `GamePhase` 仅有 `MORNING | AFTERNOON | EVENT | SETTLEMENT`，缺少标题画面（TITLE）、每日开场白（OPENING）、结局演出（ENDING）三个关键生命周期相位。

**处理**：TECH_ARCH 已重写，`GamePhase` 扩展为完整 7 相位，并补充了全量转换规则表。PRD 未修改，其流程定义作为需求源头继续有效。

---

### Patch-003 [2026-04-18] GameState 接口补全（��落地）

**冲突**：原 GameState 缺少 PRD 9.2 要求的 `version`、`savedAt`、`actionStats` 字段，且 `LogEntry` 类型从未定义。

**处理**：TECH_ARCH 已补充 `LogEntry`、`ActionStats` 接口定义，GameState 增加全部缺失字段及初始值常量 `INITIAL_STATE`。

---

### Patch-004 [2026-04-18] 结局判定与事件抽取算法下沉（已落地）

**冲突**：结局判定规则（PRD 5.4 第 5 步）和事件抽取算法（PRD 5.4 第 4 步）仅以自然语言存在于 PRD 中，技术文档无对应规格，AI 编码时无法直接引用。

**处理**：TECH_ARCH 新增第 4 节（结局判定算法，含 TypeScript 伪代码和执行流程图）和第 5 节（事件抽取算法，含完整伪代码）。两处规则均严格对齐 PRD 原文，未做任何语义变更。

---

### Patch-005 [2026-04-18] 行动系统数据结构化（已落地）

**缺漏**：PRD 5.3 定义了 4 种行动的效果值，但仅以 Markdown 表格呈现，无结构化数据定义。AI 编码时需手动从文档提取数值，容易出错。

**处理**：TECH_ARCH 新增第 6 节，将 4 种行动的效果常量以 Action ID + 数值映射表形式固化，并明确双重校验约束（UI 层 + Store 层）。

---

### Patch-006 [2026-04-19] 数值平衡风险 — 跳槽路线过快（Resolved）

**风险**：推演最优跳槽路径（刷八股文 + 带薪拉屎交替），约 5 天即可达成 interview ≥ 80 触发 GE，快于 PRD 检查清单预期的 7-10 天。

**处理**：采用组合微调方案，两项数值同步调整：
1. "刷八股文"面试准备度增量 +10 → +8（降低跳槽速度）
2. "带薪拉屎"新增怀疑度成本 0 → +3（增加策略代价）

**效果**：纯 STUDY+SLACK 循环需 ~9 天达标（无事件），配合事件加成约 6-8 天，符合 7-10 天目标区间。怀疑度增长加速迫使玩家在跳槽路线和安全结局之间做取舍。

---

### Patch-007 [2026-04-18] 顶栏 UI 规范补全（已落地）

**缺漏**：PRD 7.2 要求"顶部区域：显示游戏进度（当前天数/总天数），提供设置入口"，但原 UI_DESIGN_SYSTEM 仅定义三栏布局（Sidebar / Main Editor / Terminal），缺少 Top Bar。

**处理**：UI_DESIGN_SYSTEM 第 3 节布局定义新增 Top Bar（固定高度 h-12），展示游戏标题、天数进度和全局设置入口（音频开关、音量滑块、重新开始按钮）。

---

### Patch-008 [2026-04-18] 音频技术方案补全（已落地）

**缺漏**：PRD 第 8 章详细定义了音频需求（音效分类、BGM 场景、全局静音、音量独立调节、懒加载），但原 TECH_ARCH 完全没有音频相关的技术选型或架构说明。

**处理**：TECH_ARCH 新增第 10 节（音频架构），涵盖：
- 选型：Howler.js
- 独立音频 store（`useAudioStore`），不混入 GameState
- 资源目录结构与 BGM 场景映射表
- 懒加载策略（首屏零音频、首次交互触发 BGM、SFX 按需加载）
- 统一音频管理器（`audioManager.ts`），禁止组件直接实例化 Howl

---

### Patch-009 [2026-04-18] 行动数据入 GAME_CONTENT（已落地）

**缺漏**：GAME_CONTENT.md 作为"静态数据库"文档，缺少行动效果的结构化数据。AI 编码时行动效果仅能从 TECH_ARCH 表格或 PRD 文本中提取，不符合"数据层与逻辑层分离"原则。

**处理**：GAME_CONTENT.md 新增第 1 节（行动效果数据），含 `ActionDef` 接口定义和 4 种行动的完整 JSON 数据。原章节编号顺延（开场白 → 2，事件库 → 3，结局 → 4）。



### Patch-010 [2026-04-18] S-1 修复：Day 30 日结清算跳过日常检查（已落地）

**冲突**：TECH_ARCH §4.3 的 SETTLEMENT 流程将 Day 30 和非 Day 30 做了互斥分支，Day 30 仅执行 `checkFinalEnding` 而跳过 `checkDailyEnding`。导致 Day 30 日结扣精力后 energy 降到 0 时不会触发 BE_DEATH，而是落入 BE_FIRED。

**处理**：TECH_ARCH §3.3（相位转换表）、§4.2（checkFinalEnding 前置注释）、§4.3（SETTLEMENT 流程伪代码）三处同步修正。新流程为：所有天数统一先执行 `checkDailyEnding`，仅当其返回 null 且 day=30 时才追加 `checkFinalEnding`。

---

### Patch-011 [2026-04-18] S-2 裁决：BE_FIRED Day 30 触发条件以 §5.4 优先级兜底为准（已落地）

**冲突**：PRD §5.4 第 6 条将 BE_FIRED 定义为"以上都不满足"的 catch-all，而 §5.5 结局清单表格将其 Day 30 条件描述为"绩效 < 20"。两处语义矛盾。

**裁决**：以 §5.4 的优先级兜底逻辑为准。§5.5 的"绩效 < 20"为典型场景描述，不作为硬性判定条件。理由：优先级兜底逻辑更简洁、无遗漏风险，且与 TECH_ARCH 中 `checkFinalEnding` 的 catch-all 实现一致。PRD §5.5 原文不做修改，开发时以本 Patch 为准。

---

## 3. 已解决的冲突 (Resolved Conflicts)

- 暂无。

---

## 4. 功能补丁 (Feature Patches)

### Patch-F01 [2026-04-19] 怀疑度惩罚机制落地（已落地）

**缺漏**：PRD §5.1 状态字典明确定义了"怀疑度 ≥ 70：增加高危负面事件触发概率"，但事件抽取算法（TECH_ARCH §5.1）未实现此机制。怀疑度在日结判定中无任何影响，导致该数值在大部分游戏流程中缺乏策略意义。

**处理**：
1. 事件数据（events.json）新增 `highRisk: boolean` 可选字段，标记 6 个与被监控/裁员相关的高危事件（EV_002, EV_007, EV_011, EV_012, EV_017, EV_020）。
2. 事件抽取算法（events.ts / TECH_ARCH §5.1）新增渐进式权重修正和空事件概率调整。
3. 高危事件视觉效果区分：EventDialog 中高危事件使用红色边框、红色标题栏背景和脉冲动画的 "⚠ 高危事件" 标签。
4. 高危事件数值强化：6 个高危事件的选项效果值整体增大，增加选择压力。

**详细规则**（TECH_ARCH §5.1 伪代码同步更新）：

| 怀疑度阈值 | 高危事件权重倍率 | 空事件概率 |
|-----------|----------------|-----------|
| < 50 | 1x | 10% |
| ≥ 50 | 2x | 10% |
| ≥ 80 | 3x | 5% |

**效果**：跳槽路线在 ~Day 5 触发怀疑度 ≥ 50 阈值，高危事件出现概率开始上升；~Day 8+ 达到 ≥ 80 后进入高压阶段，事件更频繁且高��事件占绝对主导。

---

### Patch-F02 [2026-04-26] 怀疑度惩罚机制强化（已落地）

**缺漏**：怀疑度仅影响高危事件权重，数值堆到 100 也无实质后果。玩家可无视怀疑度正常通关，甚至在高怀疑度下触发 GE_OFFER。

**处理**：
1. **高压晨间事件**：怀疑度 ≥ 70 时，每天开场有概率（30%~60%，随怀疑度线性增长）触发强制负面事件，直接扣减属性值（精力 -10~-15、KPI -5~-10、怀疑度 +5~+10 等）。
2. **封锁提前跳槽**：`checkDailyEnding` 中 GE_OFFER（interview ≥ 80）新增前置条件 `suspicion < 85`。高怀疑度意味着被公司盯得太紧，无法秘密面试拿 offer。
3. **高危事件效果放大**：怀疑度 ≥ 80 且事件标记 `highRisk` 时，选项中的负面效果值放大 1.5x。

**数据新增**：
- `src/data/pressure-events.json`：6 个高压晨间事件定义
- `GameState` 新增 `suspicionPressure: string | null` 字段
- Store 新增 `checkSuspicionPressure()` 和 `acknowledgePressure()` 两个 action

**效果**：怀疑度从"可无视的数值"变为真正需要管理的风险。高怀疑度路线会遭遇持续的精神压力和属性惩罚，玩家必须在"刷题速度"和"暴露风险"之间做出取舍。

---

### Patch-F03 [2026-04-26] 数值交叉影响矩阵与 Buff/Debuff 系统（已落地）

**缺漏**：四个核心数值彼此完全独立，缺乏"一环崩盘引发连锁反应"的真实职场张力。高怀疑度/低精力对行动效果无反馈。玩家没有"管理整体状态"的动力。

**处理**：
1. **状态条件系统**：新增 `src/data/status-conditions.json`，定义 8 个 Buff/Debuff 条件（4 buff + 4 debuff），每个条件含触发阈值、效果倍率、图标和 tooltip 文案。
2. **实时评估**：每次行动/事件/结算后自动调用 `evaluateStatusConditions()`，检测当前数值是否触发新状态。同源条件互斥（取最高 severity），跨源可共存。
3. **效果叠加**：新增 `applyStatusToDeltas()` 函数，在 action/event delta 生效前叠加 buff/debuff 的倍率（gain multiplier 影响正向收益，cost multiplier 影响负向消耗）。
4. **Buff 栏 UI**：在 Sidebar 数值面板下方新增 `BuffBar` 组件，横向排列 32×32 图标方块（buff 绿框，debuff 红框）。获得时播放 spring 弹入动画 + 终端日志通知。悬浮显示三行 tooltip（标题/效果数值/趣味说明）。
5. **DB 状态清单**：

| Buff | 触发 | 效果 |
|------|------|------|
| 老板信任 | suspicion ≤ 25 | KPI 收益 +20%, suspicion 增长 -30% |
| 精力充沛 | energy ≥ 75 | 精力消耗 -30% |
| 核心骨干 | KPI ≥ 75 | KPI 收益 +25% |
| 如鱼得水 | KPI≥65 & energy≥60 & suspicion≤35 | 所有收益 +15% |

| Debuff | 触发 | 效果 |
|--------|------|------|
| 信任危机 | suspicion ≥ 65 | KPI 收益 -25% |
| 严密监控 | suspicion ≥ 85 | 面试收益 -30%, suspicion 增长 +30% |
| 精神透支 | energy ≤ 25 | KPI 收益 -30%, 精力消耗 +30% |
| 身心崩溃 | energy ≤ 15 | 所有收益 -20%, 精力消耗 +50% |

**数据新增**：
- `src/data/status-conditions.json`：8 个状态条件定义
- `src/components/game/BuffBar.tsx`：Buff 栏 UI 组件
- `GameState` 新增 `activeStatuses: string[]` 字段
- Store 新增 `evaluateStatusConditions()` action 和 `computeActiveStatuses()` / `applyStatusToDeltas()` 辅助函数
- GAME_VERSION → 1.2.0

---

### Patch-F04 [2026-04-26] 数值平衡修复：结局门槛 + 即时惩罚 + 连选惩罚（已落地）

**缺漏**：Day 30 GE_OFFER 无视怀疑度；STUDY+SLACK 固定套路无惩罚；KPI 只涨不跌；ENERGIZED buff 门槛过低导致滚雪球。

**处理**：

1. **Day 30 GE_OFFER 加怀疑度门槛**：`checkFinalEnding` 中 GE_OFFER 新增 `suspicion < 70` 条件。早期检查（`checkDailyEnding`）已有 `suspicion < 85` 门槛，最终检查不再绕开。

2. **即时抓包（Spot Check）**：新增 `checkSpotCheck()` 函数，选择 STUDY/SLACK 且怀疑度 ≥ 70 时概率触发实时惩罚。高怀疑度时风险陡增（70% 概率触发）。
   - suspicion≥70 + STUDY: 40% 触发，SUS+5
   - suspicion≥85 + STUDY: 70% 触发，SUS+8, INT-4（面试收益减半）
   - suspicion≥70 + SLACK: 30% 触发，SUS+3, ENR 减半
   - suspicion≥85 + SLACK: 50% 触发，SUS+5, ENR 归零, KPI-5

3. **连选惩罚（Action Streak）**：新增 `actionStreak` 状态追踪连续选择同一行动的次数。切换行动时重置计数。连续 2/3/4+ 次选择同一行动，基础效果逐步衰减。
   - SLACK: +20→+14→+8→+3, SUS+3→+5→+7→+10
   - STUDY: ENR-10→-13→-16→-20, SUS+5→+7→+9→+12
   - WRITE_CODE: ENR-10→-13→-16→-20, SUS-2→-1→0→+1
   - FIX_BUG: ENR-20→-25→-30→-35, KPI+15→+15→+10→+5
   
   按钮右上角显示角标（×2 琥珀, ×3 红色, ×4+ 红色脉冲），hover 提示说明。

4. **ENERGIZED buff 门槛提升**：energy 触发阈值 75→80，消耗减免 -30%→-20%。减少滚雪球效应。

5. **CORE_MEMBER buff 限定工作行动**：KPI 收益 +25% 仅对 WRITE_CODE/FIX_BUG 生效，不再无条件加成 STUDY/SLACK。

**代码变更**：
- `src/logic/endings.ts`：`checkFinalEnding` GE_OFFER 加 suspicion < 70
- `src/data/status-conditions.json`：ENERGIZED 阈值和效果调整
- `src/store/useGameStore.ts`：新增 `actionStreak` 字段、`getStreakAdjustedEffects()`、`checkSpotCheck()`、`STREAK_EFFECTS` 表；`applyStatusToDeltas()` 新增 actionId 参数
- `src/components/game/Editor.tsx`：ActionContent 添加连选角标 UI

---

### Patch-F05 [2026-04-26] 技能加点系统 + 动态行动池（已落地）

**缺漏**：每日行动固定 4 个，30 天无变化；缺乏中期目标和成长感。

**处理**：

1. **技能加点系统**：
   - 新增 `src/data/skills.json`：12 个技能节点（4 分支 × 3 层），含效果、消耗、前置条件、解锁内容。
   - 货币"成长点"每周结算（Day 7/14/21）：基础值 + KPI 系数。每局独立，不跨周目。
   - 技能效果分三类：
     - 被动加成（T1/T2）：如精力消耗 -10%、KPI 收益 +10%、怀疑度增长 -10%。
     - 特殊行动（SOCIAL_T2）：消耗 3pt 降 10 SUS。
     - 解锁新内容（T3）：新行动"架构重构"（代码效率 III）、"拉帮结派"（社交技巧 III）、隐藏事件"午间小憩"/"猎头上门"。

2. **动态行动池**：
   - 新增 `src/logic/actionPool.ts`：每次从 12 个行动（4 核心 + 8 条件）中抽取 4 个。
   - 规则：≥2 个核心行动，≥1 休息 + ≥1 工作行动，条件行动按状态/day/技能筛选。
   - `src/data/actions.json` 扩充至 12 个行动：核心 4 个（写代码/修Bug/刷题/拉屎）+ 条件 6 个（帮助新人/重构/写博客/技术分享/刷知乎/加班）+ 技能解锁 2 个。

3. **周度复盘 UI**：
   - 新增 `src/components/game/WeekReview.tsx`：全屏弹窗，展示本周数值、可用成长点、技能树（4 列 × 3 行），点击购买。
   - 结算日（7/14/21 天）自动弹出，关闭后正常进入下一天。

**代码变更**：
- `src/data/skills.json`：**NEW** 12 个技能节点
- `src/data/actions.json`：从 4 个扩充至 12 个行动
- `src/logic/actionPool.ts`：**NEW** 动态行动池抽取算法
- `src/components/game/WeekReview.tsx`：**NEW** 周度复盘弹窗
- `src/store/useGameStore.ts`：新增 `skillPoints`/`skills`/`showWeekReview` 字段，`earnSkillPoints()`/`purchaseSkill()`/`spendPointsForSuspicion()`/`closeWeekReview()` 4 个 action，`applySkillToDeltas()` 辅助函数
- `src/app/page.tsx`：引入 WeekReview
- `src/components/game/Sidebar.tsx`：新增 SkillIcons 组件
- `src/components/game/Editor.tsx`：ActionContent 改用 `sampleActionPool()` 动态获取行动列表
- GAME_VERSION → 1.3.0



---

### Patch-012 [2026-05-02] 文档全面审计与对齐

**冲突/缺漏**：经过多轮迭代（F01-F05），代码行为已大幅超出文档描述范围。以下文档存在系统性过期：

**1. PRD.md 过期项**：
- §2.2 "不做技能树或角色成长系统" — F05 已实现完整技能树（12技能/4分支/3层），PRD应标记为已实现。
- §5.3 行动清单仅列出4个固定行动 — 实际有12个（4核心 + 8条件），使用动态行动池（`actionPool.ts`）。
- §5.4 流程缺少"打断"（Interruption）环节：MORNING→AFTERNOON 时有25%概率触发打断事件。

**2. TECH_ARCH.md 过期项**：
- §2.1 GameState 接口缺少8个字段：`dayModifier`、`interruption`、`suspicionPressure`、`activeStatuses`、`actionStreak`、`skillPoints`、`skills`、`showWeekReview`。
- §2.2 版本号为 "1.0.0"，实际代码为 "1.3.0"。
- §3.3 相位转换表未体现打断、压力事件、周度复盘流程。
- §6 行动系统仅列出4行动，实际为12行动 + 动态抽取。
- §7 目录结构缺少：`actionPool.ts`、`WeekReview.tsx`、`BuffBar.tsx`、6个数据文件（`modifiers.json`、`interruptions.json`、`pressure-events.json`、`status-conditions.json`、`skills.json`、`event-categories.json`）、`hooks/` 目录。
- 缺少状态条件系统（Buff/Debuff）、技能系统、连选惩罚、即时抓包、打断系统、压力事件系统的技术规格。

**3. GAME_CONTENT.md 过期项**：
- §1 行动数据仅4个，实际12个。
- §3 事件库样例旧称"共 20 个事件"；当前实际为65个（EV_001-EV_065），含14个高危事件和5个QTE事件。
- 缺少 `modifiers.json`、`interruptions.json`、`pressure-events.json`、`status-conditions.json`、`skills.json`、`event-categories.json` 的数据Schema定义。

**4. AGENTS.md 过期项**：
- §3 仓库结构严重过期，缺少所有 F01-F05 新增文件。
- §7.4 说"无测试框架"且推荐 Vitest — 实际已使用 Playwright（`package.json` 有 `test:e2e`）。
- §6 Open Risks 中 Patch-006 已被后续平衡补丁（F04连选惩罚 + F02怀疑度门槛）部分缓解。

**处理**：
- 本次审计将直接更新所有5份文档（PRD、TECH_ARCH、GAME_CONTENT、DOC_AUDIT、AGENTS.md），使其与代码 v1.3.0 完全对齐。
- 不修改任何代码。文档变更以"补齐现实"为原则，不虚构未实现的功能。


---

## 5. Flutter 迁移审计 (Migration Audit)

### Patch-F06 [2026-05-03] Flutter 迁移架构适配（已落地）

**背景**：项目从 Web (Next.js + React + Zustand) 迁移至 Flutter (Dart + Riverpod + SharedPreferences)。

**变更摘要**：
- 状态管理：`Zustand` → `Riverpod Notifier`（`lib/state/game_notifier.dart`）
- 持久化：`localStorage` → `SharedPreferences`（`lib/services/save_service.dart`）
- 音频：`Howler.js` → `audioplayers`（`lib/services/audio_manager.dart`）
- 数据处理：TypeScript `interface` → Dart `class` + `fromJson`/`toJson`（`lib/models/`）
- 游戏数据：`src/data/*.json` → `assets/data/*.json`（JSON 内容不变）
- 纯逻辑函数（`endings.dart`, `events.dart`, `game_loop.dart`, `action_pool.dart`, `action_resolver.dart`, `status_evaluator.dart`）逐行翻译自 TypeScript 原版，算法完全一致
- UI 组件（`lib/widgets/` 和 `lib/screens/`）从 React 组件重建为 Flutter Widget
- 测试框架：Playwright → `flutter test`（单元+集成测试 248 cases）

**前置补丁状态**：Patch-001 至 Patch-F05 定义的**所有游戏逻辑规则在 Flutter 版中保持不变**（clamp 强制、7 相位状态机、结算顺序、Patch-010/011、怀疑度门槛、连选惩罚、技能树等）。


---

### Patch-F07 [2026-05-03] 横屏 UI 布局适配（已落地）

**背景**：手机端 UI 从竖屏 IDE 布局改为横屏三层结构。

**变更摘要**：
- 方向锁定：`portraitUp/Down` → `landscapeLeft/Right`
- 布局结构：`TopBar → Row(Sidebar+Editor+Terminal)` → `TopBar → Row(LeftDate+Editor+RightStats) → CollapsibleTerminal`
- LeftDatePanel (72dp)：圆形天数 + /30 + 30天时间线（4点/行，8行）
- RightStatsPanel (150dp)：4 属性竖排 + Buff/Debuff 点击 Tooltip + 相位标签
- 行动按钮：`GridView.count 2×2` 等大网格，间距 16dp
- Terminal 可折叠（默认展开 72px，收起时只显示标题栏）
- CRT 扫描线覆盖层已移除（`crt_overlay.dart` 保留文件但不再调用）
- 旧 BuffBar 组件已废弃（改为 `_RightBuffBar` 内联于 sidebar.dart）
- 自动相位推进：从 `didChangeDependencies` + `ref.listenManual` 简化为 `build()` 中直接调用 `_tryAdvance(s)`
- 游戏描述："browser-based" → "Android mobile"


---

## 6. 动画与交互增强审计 (Animation & Interaction Audit)

### Patch-F08 [2026-05-04] 动画系统全面实施

**背景**：TODO.md 2.3-2.6 各项动画逐步实施完成。

**变更摘要**：
- 相位切换：`AnimatedSwitcher(300ms)` + `transitionBuilder` scale+fade（进入+退出双向镜像）
- 弹窗弹出：`_PopIn` 组件（可配置延迟，默认 300ms，行动卡片 500ms）scale+fade
- 背景交叉淡入淡出：8 张背景图预加载 + `AnimatedSwitcher(500ms, ValueKey)` 交叉淡入淡出
- 结算加载圈：`TweenAnimationBuilder` 淡入
- Buff/技能芯片弹性入场：`TweenAnimationBuilder(Curves.elasticOut, 350ms)`
- 终端日志滑入：每条日志 slide+fade 入场
- 终端折叠/展开：`AnimatedSize(250ms)`
- 周度复盘面板弹出：`TweenAnimationBuilder` scale+fade
- 退出动画：`AnimatedSwitcher` 的 `transitionBuilder` 自动对离开的旧内容施加反向 scale+fade

---

### Patch-F09 [2026-05-04] 毛玻璃系统标准化

**背景**：高斯模糊从最初的全局背景模糊改为悬浮面板毛玻璃。

**变更摘要**：
- 新建并公开 `GlassPanel` 组件，全局统一参数：sigma 12、主题化 overlay/border
- 最外层包裹 `RepaintBoundary` 防止触摸/滑动时 BackdropFilter 被 Flutter 丢弃
- `_PopIn` 的 `Opacity` 使用 `0.01 + 0.99 * value`，确保 BackdropFilter 图层永不消失
- 事件选项按钮背景改为 `Colors.white.withValues(alpha: 0.05)` 高透
- 应用到：Opening、Action Cards、Event、Interruption、Pressure 共 5 类面板

---

### Patch-F10 [2026-05-04] Overscroll 防护

**变更摘要**：
- 所有滚动组件（ActionContent GridView、OpeningContent SingleChildScrollView、EventContent SingleChildScrollView）使用 `ClampingScrollPhysics()` + `ScrollConfiguration(overscroll: false)`
- 防止 iOS 回弹和 Android 12+ 拉伸形变击穿 BackdropFilter

---

### Patch-F11 [2026-05-04] 触觉反馈与按压缩放

**变更摘要**：
- 所有交互按钮实现 `AnimatedScale` (100ms, easeInOutCubic) + `HapticFeedback.lightImpact()`
- 行动卡片 `_ActionCard` 和事件选项 `_EventOption` 的 `onTap` 有 150ms 延迟确保按压动画完整播放
- 新建 `_TapButton` (editor.dart) 和 `_WeekButton` (week_review.dart) 复用组件
- 缩放比：行动卡片 0.95、事件选项 0.97、其他按钮 0.93

---

### Patch-F12 [2026-05-04] 终端系统优化

**变更摘要**：
- 自动滚动：`TerminalWidget` 持有 `ScrollController`，每条新日志自动 `animateTo(maxScrollExtent, 200ms)`
- 合并工具栏：`_CollapsibleTerminal` 将原来分离的 header 行和折叠按钮合并为一行 `[▼] LOG // CH0 (##) TERMINAL ▼`
- 去除冗余的 `ERR_LOG` / `SYS_STATUS` 标签

---

### Patch-F13 [2026-05-04] 技能撤销与侧边栏布局

**变更摘要**：
- 新建 `refundSkill()` 方法 — 退还成长点并移除技能
- `WeekReview` 二次点击撤销机制：首次点击红色高亮"再次点击撤销"，二次点击执行撤销
- 侧边栏 buff/技能芯片改为 `Wrap` 横向排布，中间区域包裹 `Expanded(SingleChildScrollView)` 防止溢出


---

### Patch-F14 [2026-05-04] 动态主题系统 (Game-State Aware Theme)

**背景**：UI 配色仅有一套深色主题，未利用颜色区分游戏状态（上午/下午/危机）。

**变更摘要**：
- 新建 `lib/state/theme_provider.dart` — `GameTheme` 类 + `GameTheme.compute()` 纯派生 + Riverpod Provider
- 三套主题：**Dark**（默认）、**Light**（MORNING/OPENING/打断）、**Danger**（高危事件/压力事件/精力≤10/KPI≤10）
- 优先级：Danger > Light > Dark
- Light 主题下霓虹色约 80% 亮度适配，文字色反转为深色；背景/面板/终端/毛玻璃色系按主题切换
- 过渡动画：`AnimatedTheme(500ms)` + UI 组件 `AnimatedContainer(500ms)`
- `GlassPanel` 改为 `ConsumerWidget`，从 `themeProvider` 读取 `glassOverlay` 和 `glassBorder`
- TopBar / LeftDatePanel / RightStatsPanel / TerminalWidget / Editor Container 全部接入主题色
- 主题纯派生自 GameState，进入 OPENING 自动复位，无"卡死"风险

---

## 7. 音频系统审计 (Audio System Audit)

### Patch-F15 [2026-05-10] 音频系统完整实现（SFX + BGM）

**背景**：音频系统仅有代码骨架（AudioManager / AudioNotifier / AudioState），音频文件全部缺失，无任何 BGM/SFX 触发逻辑接入。

**变更摘要**：

1. **SFX 系统（5 个音效）**：
   - 音频文件：`assets/audio/sfx/` — `click.ogg`、`event.wav`、`alert.wav`、`glitch.wav`、`success.wav`
   - AudioManager 新增 `_sfxFiles` 映射表（ID→文件名），支持混合格式（ogg/wav），跨平台迁移只需改此表
   - 触发点：
     - `click`：所有交互按钮的 `onTapDown`（editor.dart `_TapButton`/`_ActionCard`/`_EventOption`/`OpeningContent`、title_screen `_CyberButton`、top_bar 静音按钮、week_review `_SkillNode`/`_WeekButton`、game_screen 终端折叠、ending_screen RESTART）
     - `event`：普通随机事件弹窗出现时（game_screen `_tryPlaySfx`）
     - `alert`：高危事件 / 打断事件 / 怀疑度压力事件出现时（game_screen `_tryPlaySfx`）
     - `glitch`：BE 结局（BE_DEATH / BE_FIRED）GlitchPhase 开始时（ending_screen `initState`）
     - `success`：好/正常结局（GE_OFFER / NE_PEACE / HE_KING）RevealPhase 开始时（ending_screen `initState`）
   - SFX 去重：`_tryPlaySfx` 使用 `_sfxPlayedKey` 防止同一弹窗重复触发 SFX

2. **BGM 系统（3 首循环背景音乐）**：
   - 音频文件：`assets/audio/bgm/` — `title.mp3`（~60s）、`daily.mp3`（~60s）、`tension.mp3`（~102s）
   - AudioManager 新增 `_bgmFiles` 映射表（ID→文件名）
   - BGM 场景切换：
     - `title`：TITLE 画面（title_screen `initState`）
     - `daily`：OPENING / MORNING / AFTERNOON / SETTLEMENT（game_screen `_syncBgm`）
     - `tension`：energy≤20 或 kpi≤20 时替换 daily（game_screen `_syncBgm`）
     - 停止：ENDING 阶段停止所有 BGM（ending_screen `initState`）
   - Crossfade：20 步×50ms = 1s 渐出 + 1s 渐入，避免硬切
   - 循环：`setReleaseMode(ReleaseMode.loop)`

3. **音频焦点配置**：
   - BGM Player：`AndroidAudioFocus.gain`（持有音频焦点）
   - SFX Player：`AndroidAudioFocus.none`（不请求焦点，不中断 BGM）
   - 确保 BGM 和 SFX 可同时播放

4. **涉及文件**：
   - `lib/services/audio_manager.dart` — 重写：映射表 + crossfade + 音频焦点
   - `lib/screens/game_screen.dart` — 新增 `_tryPlaySfx`、`_syncBgm`
   - `lib/screens/title_screen.dart` — initState 播放 title BGM
   - `lib/screens/ending_screen.dart` — initState 停止 BGM + 播放结局 SFX
   - `lib/widgets/editor.dart` — click SFX 接入 4 处
   - `lib/widgets/top_bar.dart` — 静音按钮 click SFX
   - `lib/widgets/week_review.dart` — click SFX 接入 2 处

**效果**：音频系统从"空壳"变为完整可用。SFX 提供交互反馈，BGM 营造氛围且根据游戏状态自动切换，两者互不干扰。

---

### Patch-F16 [2026-05-10] 开场视频系统

**背景**：标题画面点击 NEW GAME 后增加全屏开场视频，增强沉浸感。CONTINUE 不播放。

**变更摘要**：

1. **依赖与资产**：
   - 新增 `video_player: ^2.9.2` 依赖（lock/cache 可解析到更新兼容版本）
   - 新增 `assets/video/` 资产目录
   - 视频文件 `assets/video/intro.mp4`

2. **GameState 扩展**：
   - 新增 `bool showIntroVideo` 字段（瞬态 UI 状态，不序列化），默认 `false`

3. **GameNotifier 新增方法**：
   - `startIntroVideo()`：设置 `showIntroVideo = true`，停止当前 BGM
   - `finishIntroVideo()`：设置 `showIntroVideo = false`，调用 `startNewGame()` + `assignDayModifier()` + `checkSuspicionPressure()`

4. **新建 `VideoIntroScreen`**（`lib/screens/video_intro_screen.dart`，~170 行）：
   - `VideoPlayerController.asset` 全屏播放（`FittedBox + BoxFit.cover`）
   - `AnimationController(1000ms)` 驱动黑色遮罩淡入淡出
   - 底部 `GlassPanel` 毛玻璃 + `TypewriterText`（speed:25）显示游戏背景文案
   - "点击跳过" 提示，点击任意位置 → fade-out → 进入游戏
   - Android 返回键 → 等同跳过（`PopScope`）
   - 初始化失败容错 → 直接进入游戏
   - `WidgetsBindingObserver` 前后台生命周期管理

5. **GameScreen 集成**：
   - `build()` 中 watch `showIntroVideo`，为 `true` 时直接返回 `VideoIntroScreen()`（在 `AnimatedSwitcher` 之外）

6. **TitleScreen 修改**：
   - `[ NEW GAME ]` onTap 简化为 `clear() + startIntroVideo()`
   - `[ CONTINUE ]` 不变

**涉及文件**：`pubspec.yaml`, `lib/models/game_state.dart`, `lib/state/game_notifier.dart`, `lib/screens/video_intro_screen.dart`（NEW）, `lib/screens/game_screen.dart`, `lib/screens/title_screen.dart`, `lib/widgets/editor.dart`（`_GlassPanel` → `GlassPanel` 公开）

---

### Patch-F17 [2026-05-10] QTE 快速反应事件系统 — 「致命的 CSS 绝对居中」

**背景**：在纯文字 A/B 选择事件之外，引入 QTE 玩法类型。玩家需要在移动的"div"方块对准容器判定框时按下锁定按钮，根据偏移量获得 Perfect/Good/Miss 三档判定及对应数值效果。

**变更摘要**：

1. **数据模型**（`lib/models/qte_config.dart`，NEW）：
   - `QteResult` 枚举：`perfect`, `good`, `miss`
   - `QteConfig` 类：`speedBase`, `speedSuspicionScale`, `timeLimitMs`, `timeLimitSuspicionReduce`, `perfectThreshold`(8px), `goodThreshold`(24px), `tauntPool`, `effects`（三档 stat deltas）
   - `effectiveSpeed(suspicion)`, `effectiveTimeLimit(suspicion)`, `deltasFor(result)` 方法
   - `GameEvent` 新增可选字段 `qteConfig: QteConfig?`

2. **QTE 事件数据**（`assets/data/events.json`）：
   - 新增 EV_061~EV_065，5 个 QTE 事件（CSS 绝对居中 / 垂直居中难题 / IE 兼容地狱 / 响应式断点危机 / z-index 层叠战争）
   - 事件总数 60→65，高危事件 12→14
   - 各 QTE 事件仍保留两个 schema-compatible `options`；QTE 判定效果由 `qteConfig` 控制

3. **QteGame 组件**（`lib/widgets/qte_game.dart`，~360 行，NEW）：
   - `ConsumerStatefulWidget`，独立解耦：输入 `QteConfig` + `suspicion` → 输出 `onComplete(QteResult)`
   - `AnimationController` 驱动 3 阶段移动轨迹：正弦波(0-25%) → 随机步进(25-70%) → 螺旋收束(70-100%)
   - 两个 `GlobalKey` 获取容器/方块 RenderBox 实时位置
   - `_AnimatedTargetZone`：neonCyan 呼吸脉动虚线判定框(60×44)
   - `_LockButton`：`AnimatedScale` + `HapticFeedback` + `click SFX`
   - 背景图 `QTE.png`（ColorFilter.darken 暗化叠加）
   - 倒计时显示，超时按 Miss 处理

4. **QteResultOverlay**（`lib/widgets/qte_result_overlay.dart`，~190 行，NEW）：
   - Perfect：18 个 neonGreen/neonCyan 粒子爆散
   - Good：neonAmber 脉动环
   - Miss：neonRed 全屏闪烁 + 随机嘲讽文案
   - 中心结果卡片（PERFECT/GOOD/MISS + 副标题）
   - 用户点击画面后消失（非自动消失）

5. **Editor 集成**（`lib/widgets/editor.dart`）：
   - `EventContent` 检测 `event.qteConfig != null` → 渲染 `QteGame` 替代 A/B 按钮
   - QTE 专用背景 `daily-work.png`（Editor 级别背景图层，与其他相位背景同级）
   - QTE 分支 header 压缩（标题/描述字号缩小、行间距收紧）

6. **GameNotifier 扩展**：
   - `resolveQteEvent(eventId, result)`：应用 `qteConfig.deltasFor(result)` stat deltas（clamp 铁律），追加 Graded 日志，过渡到 SETTLEMENT
   - `triggerEvent()` 修改：固定 QTE 日（Day 5/10/15/20/25）强制从 QTE 事件池抽取

7. **GameScreen QTE 适配**：
   - `_GameLayoutState` 跟踪 `_prevEventId`，进入 QTE 事件时自动折叠终端（`_terminalOpen = false`）

8. **周总结背景**（`lib/widgets/week_review.dart`）：
   - 应用 `office-politics.png` 背景图（Stack + 暗化叠加，与其他背景同级）

9. **日期面板特殊标记**（`lib/widgets/sidebar.dart`）：
   - QTE 日（5/10/15/20/25）：青色
   - 周总结日（7/14/21）：琥珀色
   - 冲突日：红色；当前 QTE 日与周复盘日无重叠，红色仅作为预留图例
   - 点击面板弹出图例对话框说明颜色含义

10. **左侧面板图例**（`lib/widgets/sidebar.dart`）：
    - `_showLegend()` 函数：AlertDialog 展示 4 色图例（当前天数/CSS居中考核/周度复盘结算/考核+复盘同日）

**涉及文件**：`lib/models/qte_config.dart`（NEW）, `lib/models/game_event.dart`, `lib/widgets/qte_game.dart`（NEW）, `lib/widgets/qte_result_overlay.dart`（NEW）, `lib/widgets/editor.dart`, `lib/widgets/week_review.dart`, `lib/widgets/sidebar.dart`, `lib/state/game_notifier.dart`, `lib/screens/game_screen.dart`, `assets/data/events.json`, `assets/backgrounds/QTE.png`, `assets/backgrounds/daily-work.png`, `assets/backgrounds/office-politics.png`, `test/data/data_integrity_test.dart`, `test/models/models_test.dart`

**效果**：QTE 系统作为新的事件子类型无缝融入现有事件循环。通过怀疑度动态调整难度（速度 `50-70 + suspicion×(0.8-1.2)` px/s，时限 `8000-10000 - suspicion×(25-40)` ms）。架构完全解耦，QteGame 组件可复用到任何流程位置。

---

### Patch-F18 [2026-05-30] Current implementation reconciliation (landed)

**Background**: A code-vs-document audit found several stale statements after multiple Flutter iterations. This patch is the current reconciliation layer for all project documents.

**Current canonical facts**:
- Android launcher name is `Frontend Survival`; launcher icons are generated from `tmp_icon/icon.png` into `android/app/src/main/res/mipmap-*`.
- Runtime version is `2.0.0+2`; `GameState.gameVersion` is `2.0.0`.
- `GameState` has 24 fields, including transient non-serialized `showIntroVideo`.
- `GameData.init()` loads 10 JSON data files and preloads 8 background PNGs, including `assets/backgrounds/QTE.png`.
- `assets/data/events.json` contains 65 events, including 14 high-risk events and 5 QTE events (`EV_061`-`EV_065`).
- QTE events still keep exactly two `options` for parser/schema compatibility; QTE stat effects are resolved from `qteConfig`.
- Fixed QTE days are Day 5, 10, 15, 20, and 25. Week review days are Day 7, 14, and 21, so there is currently no overlapping conflict day; the red timeline legend is reserved for future overlap.
- `EndingScreen` reads ending title/text from `GameData.endings`; ending copy is not hardcoded in the widget.
- Save writes are triggered by `GameScreen` after a no-ending settlement reaches the next `OPENING`; save clear is triggered by `EndingScreen` after its glitch/reveal animation completes.
- The active HUD buff display is `_RightBuffBar` in `lib/widgets/sidebar.dart`; `lib/widgets/buff_bar.dart` is retained legacy code.
- The shared glass component is public `GlassPanel` in `lib/widgets/editor.dart`, with themed `glassOverlay`/`glassBorder`.
- The current automated suite is 248 tests across 15 Dart test files, and `flutter analyze` must return zero issues.

**Documents updated**: `PRD.md`, `TECH_ARCH.md`, `GAME_CONTENT.md`, `UI_DESIGN_SYSTEM.md`, `MIGRATION_PLAN.md`, `TODO.md`, `ONBOARDING.md`, `TESTING_GUIDE.md`, `README.md`, and `AGENTS.md`.
