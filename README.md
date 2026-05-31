# Frontend Survival

《Frontend Survival》是一款 Flutter/Android 横屏文字资源管理游戏。你扮演一名大厂前端工程师，在 30 天裁员倒计时里一边交付 KPI，一边偷偷准备面试，还要控制老板和 HR 的怀疑度。

赛博朋克终端 HUD、打字机叙事、随机职场事件、技能树、QTE 小游戏和五种结局，组成一场有点荒诞、也有点真实的职场求生模拟。

## 下载 APK

可以在 GitHub Releases 页面下载最新 APK：

[Download latest release](https://github.com/yyty947/vibe2_flutter/releases/latest)

如果不确定设备架构，下载 `universal` APK；如果想要更小体积，优先选择 `arm64-v8a`。

## 游戏目标

在 Day 1 到 Day 30 之间活下来，并尽量拿到更好的结局。

每一天你都要在有限行动点里做取舍：是写业务代码稳住 KPI，还是刷八股准备跳槽？是带薪恢复精力，还是冒险加班把绩效拉上去？所有选择都会改变你的四项核心属性。

## 核心属性

| 属性 | 含义 | 风险 |
|------|------|------|
| ENERGY 精力 | 行动消耗的体力和精神状态 | 归零会触发死亡结局 |
| KPI 绩效 | 你的工作产出和表面价值 | 归零会触发被裁结局 |
| INTERVIEW 面试度 | 为跳槽做的准备 | 达标且怀疑度不高时可触发跳槽结局 |
| SUSPICION 怀疑度 | 老板和 HR 对你的警惕程度 | 过高会触发压力事件，并封锁部分好结局 |

所有数值都限制在 0 到 100 之间。

## 每日流程

```text
OPENING     当天开场剧情
MORNING     上午行动，4 选 1
AFTERNOON   下午行动，4 选 1
EVENT       随机职场事件或 QTE
SETTLEMENT  日终结算，精力 -5，并检查结局
```

Day 7 / 14 / 21 会进入周度复盘，可以用成长点学习技能。Day 30 结算时必定触发最终结局。

## 行动系统

每个行动阶段会从 12 种行动里动态抽取 4 种。常见行动包括：

- 写业务代码：稳定提高 KPI，并降低怀疑度
- 修屎山 Bug：大幅提高 KPI，但消耗更多精力
- 偷偷刷八股文：提高面试度，也会增加怀疑度
- 带薪拉屎：恢复精力
- 帮助新人、架构重构、写技术博客、技术分享
- 刷知乎摸鱼、加班、底层架构迁移、拉帮结派

连续选择同一个行动会触发连选惩罚，收益逐步衰减。部分行动需要满足精力、日期或技能条件。

## 状态与技能

游戏会根据当前属性自动激活 Buff / Debuff：

- `TRUSTED`：低怀疑度带来更高 KPI 收益和更低怀疑增长
- `ENERGIZED`：高精力降低精力消耗
- `BURNOUT`：低精力降低收益并提高消耗
- `UNDER_SURVEIL`：高怀疑度削弱面试收益并放大风险

技能树分为 4 个分支、每支 3 层：

- 精力管理：降低精力消耗
- 代码效率：提高 KPI 收益
- 社交技巧：降低怀疑度增长
- 面试精进：提高面试收益

高级技能会解锁专属行动。复盘面板里可以撤销已学技能并退回成长点。

## QTE 事件

除了普通二选一事件，游戏还包含「CSS 绝对居中」主题 QTE。你需要在移动方块靠近判定框时锁定，根据偏移量获得 `Perfect`、`Good` 或 `Miss`，并影响当天结算。

固定 QTE 日为 Day 5 / 10 / 15 / 20 / 25，随机事件池中也可能抽到 QTE。

## 五种结局

| 结局 | 说明 |
|------|------|
| BE_DEATH | 精力归零，身体先于项目崩溃 |
| BE_FIRED | KPI 崩盘，被体面地请出大楼 |
| GE_OFFER | 成功跳槽，金蝉脱壳 |
| NE_PEACE | 拿到补偿，和平分手 |
| HE_KING | 全属性达标，活到最后 |

## 玩家小贴士

- 前期优先降低怀疑度，争取触发 `TRUSTED`
- 中期平衡精力和 KPI，再逐步刷面试度
- 后期根据目标结局冲刺，不要忽视 Day 30 的最终判定
- 精力低于 20 时优先恢复，别把自己送进危险区
- 不要一直点同一个行动，连选惩罚会很痛
- 周末限定行动和技能树往往能扭转局面

## 技术栈

- Flutter / Dart
- Riverpod
- SharedPreferences
- audioplayers
- video_player
- lucide_icons
- google_fonts

## 本地运行

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d <device_id>
```

当前目标平台是 Android，应用锁定横屏。

## 项目文档

- `docs/PRD.md`：产品规则和核心玩法
- `docs/TECH_ARCH.md`：技术架构和状态机
- `docs/GAME_CONTENT.md`：行动、事件、结局等数据说明
- `docs/UI_DESIGN_SYSTEM.md`：视觉和组件规范
- `docs/DOC_AUDIT.md`：补丁记录与文档对齐

音频素材来源记录见 `docs/AUDIO_COPYRIGHTS.txt`。
