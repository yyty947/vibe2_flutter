# 游戏内容与数据模板 (GAME_CONTENT.md)

> **摘要 (Abstract)**: 本文档充当游戏的”静态数据库”。严禁在 UI 组件代码中硬编码 (Hardcode) 剧情文本。所有的开场白、事件数据、结局文案都必须遵循此处定义的数据结构 (Schema)。AI 在构建逻辑时，应从此处读取示例数据进行渲染。
>
> **Flutter 版适配**: 原 Web 版 `src/data/*.json` → Flutter 版 `assets/data/*.json`；TypeScript `interface` → Dart `class`（位于 `lib/models/`）。JSON 数据本身无需任何修改。
>
> 最后更新：2026-05-03（Flutter 迁移）

---

## 1. 行动效果数据 (Action Effects)

**数据结构**: 每个 Action 包含 ID、显示名称、四维数值效果及可选前置条件。

```typescript
interface ActionDef {
  id: string;
  label: string;
  effects: {
    energy: number;      // 精力变化
    kpi: number;         // 绩效变化
    interview: number;   // 面试准备度变化
    suspicion: number;   // 怀疑度变化
  };
  prerequisite?: {
    field: 'energy';
    operator: '>';
    value: number;
  };
  log: string;           // 终端反馈文本模板
}
```

**完整数据**:
```json
[
  {
    "id": "WRITE_CODE",
    "label": "写业务代码",
    "effects": { "energy": -10, "kpi": 5, "interview": 0, "suspicion": -2 },
    "prerequisite": null,
    "core": true,
    "log": "[COMMIT] 提交了3个PR，绩效微升，老板觉得你很安分。"
  },
  {
    "id": "FIX_BUG",
    "label": "修屎山Bug",
    "effects": { "energy": -20, "kpi": 15, "interview": 0, "suspicion": 0 },
    "prerequisite": { "field": "energy", "operator": ">", "value": 20 },
    "core": true,
    "log": "[BUGFIX] 解决了陈年老Bug，虽然心力交瘁，但在周报上大放异彩。"
  },
  {
    "id": "STUDY",
    "label": "偷偷刷八股文",
    "effects": { "energy": -10, "kpi": 0, "interview": 8, "suspicion": 5 },
    "prerequisite": null,
    "core": true,
    "log": "[STUDY] 刷了5道Hard题。你频繁切屏引起了主管的注意。"
  },
  {
    "id": "SLACK",
    "label": "带薪拉屎",
    "effects": { "energy": 20, "kpi": 0, "interview": 0, "suspicion": 3 },
    "prerequisite": null,
    "core": true,
    "log": "[SLACK] 在厕所隔间冥想了半小时，血条恢复了！"
  },
  {
    "id": "MENTOR",
    "label": "帮助新人",
    "effects": { "energy": -15, "kpi": 10, "interview": 0, "suspicion": -5 },
    "prerequisite": null,
    "condition": { "minDay": 3, "minKpi": 40 },
    "log": "[COMMIT] 耐心解答了新同事的TS泛型问题，他在群里感谢了你。"
  },
  {
    "id": "REFACTOR",
    "label": "优化重构",
    "effects": { "energy": -30, "kpi": 20, "interview": 0, "suspicion": -2 },
    "prerequisite": null,
    "condition": { "minKpi": 50 },
    "log": "[COMMIT] 把祖传代码拆成了5个职责清晰的模块。Code Review一次过。"
  },
  {
    "id": "BLOG",
    "label": "写技术博客",
    "effects": { "energy": -10, "kpi": 5, "interview": 8, "suspicion": 0 },
    "prerequisite": null,
    "condition": { "weekendOnly": true },
    "log": "[STUDY] 整理了这周的技术积累，写了篇博客发在掘金。既练手又攒口碑。"
  },
  {
    "id": "TECH_TALK",
    "label": "参加技术分享",
    "effects": { "energy": -5, "kpi": 0, "interview": 10, "suspicion": 0 },
    "prerequisite": null,
    "condition": { "minDay": 8 },
    "log": "[STUDY] 听了隔壁组的微前端实践分享，记了满满三页笔记。"
  },
  {
    "id": "BROWSE",
    "label": "摸鱼刷知乎",
    "effects": { "energy": 10, "kpi": 0, "interview": 0, "suspicion": 1 },
    "prerequisite": null,
    "condition": {},
    "log": "[SLACK] 刷了半小时知乎热榜，看到一堆裁员帖，又焦虑又放松。"
  },
  {
    "id": "OVERTIME",
    "label": "加班赶需求",
    "effects": { "energy": -35, "kpi": 25, "interview": 0, "suspicion": -3 },
    "prerequisite": { "field": "energy", "operator": ">", "value": 40 },
    "condition": { "maxKpi": 80 },
    "log": "[COMMIT] 你一个人在空荡荡的办公室里敲到晚上十点，提了6个PR。KPI飙升但身体在报警。"
  },
  {
    "id": "ARCH_REDESIGN",
    "label": "架构重构",
    "effects": { "energy": -40, "kpi": 30, "interview": 5, "suspicion": -10 },
    "prerequisite": { "field": "energy", "operator": ">", "value": 45 },
    "condition": { "requiresSkill": "TECH_T3" },
    "log": "[COMMIT] 你主导了一次底层架构迁移。整个组都对你刮目相看。"
  },
  {
    "id": "ALLIANCE",
    "label": "拉帮结派",
    "effects": { "energy": -10, "kpi": -5, "interview": 0, "suspicion": -20 },
    "prerequisite": null,
    "condition": { "requiresSkill": "SOCIAL_T3" },
    "log": "[INFO] 你约了几个关系好的同事一起吐槽公司，大家心照不宣地互相罩着。怀疑度大降。"
  }
]
```

---

## 2. 每日开场白 (Daily Openings)

**数据结构**: `Record<number, string>` (以天数为 Key 的对象)

**样例数据**:
```json
{
  "1": "Day 1。高管在全员大会上抛出了'降本增效'四个字。空气里弥漫着不安的味道，你打开了 VS Code，假装没看到 HR 在飞书上的状态变成了'忙碌'。",
  "2": "Day 2。隔壁组的测试老哥今天没来，他的工位已经空了。主管在晨会上让大家'拥抱变化'。你喝了一口冰美式，胃里一阵痉挛。",
  "3": "Day 3。凌晨三点，老板在群里发了一个红包，标题是'兄弟们辛苦了'。你没抢，因为你知道，拿了这五块钱，今天晚上又要通宵。"
}
```

## 3. 随机事件库 (Event Bank)

**数据结构**: `Event` 接口必须包含事件 ID、触发权重、前置条件和选项。
**选项结构**: 必须明确 `effects` (数值变化数组) 和 `log` (终端反馈日志)。

```typescript
// 接口定义参考
interface EventEffect {
  type: 'ENERGY' | 'KPI' | 'INTERVIEW' | 'SUSPICION';
  value: number; // 可正可负
}

interface EventOption {
  text: string;
  effects: EventEffect[];
  log: string;
}

interface GameEvent {
  id: string;
  title: string;
  description: string;
  weight: number; // 抽取权重，默认 100
  highRisk?: boolean; // 高危事件标记（怀疑度 ≥ 50 时权重提升）
  condition: EventCondition | null; // 序列化前置条件
  options: [EventOption, EventOption]; // 必须严格为 2 个选项
}

/** 序列化条件格式（JSON 可存储） */
interface EventCondition {
  minDay?: number;
  maxDay?: number;
  minSuspicion?: number;
  maxSuspicion?: number;
  minKpi?: number;
  maxKpi?: number;
  minInterview?: number;
  maxInterview?: number;
}
```

**样例数据（完整数据见 `assets/data/events.json`，共 65 个事件（含 5 个 QTE 事件 EV_061~EV_065），含 14 个高危事件）**:
```json
[
  {
    "id": "EV_001",
    "title": "五彩斑斓的黑",
    "description": "产品经理走到你工位旁，要求给刚上线的一期需求加上'五彩斑斓的黑'主题切换，且下班前必须上预发环境。",
    "weight": 100,
    "condition": null,
    "options": [
      {
        "text": "A. 默默接下（通宵干活）",
        "effects": [{"type": "ENERGY", "value": -15}, {"type": "KPI", "value": 10}, {"type": "SUSPICION", "value": -5}],
        "log": "[WARNING] 你咬牙切齿地写了 500 行 CSS，精力大幅下降，但老板对你的服从度很满意。"
      },
      {
        "text": "B. 拔刀互怼（据理力争）",
        "effects": [{"type": "ENERGY", "value": 0}, {"type": "KPI", "value": 0}, {"type": "SUSPICION", "value": 15}],
        "log": "[INFO] 你用架构规范把产品经理怼回去了。保住了头发，但主管看你的眼神有点冷。"
      }
    ]
  },
  {
    "id": "EV_002",
    "title": "HR 的突然关心",
    "description": "飞书闪烁，HR BP 突然给你发来一条消息：'下午有空吗？去 3 号会议室聊聊发展。'",
    "weight": 50,
    "highRisk": true,
    "condition": null,
    "options": [
      {
        "text": "A. 战战兢兢去开会",
        "effects": [{"type": "ENERGY", "value": -15}, {"type": "INTERVIEW", "value": -10}],
        "log": "[ALERT] 只是例行谈话，但你被 PUA 得精神衰弱，甚至对自己能不能找到下家产生了怀疑。"
      },
      {
        "text": "B. 装死不回（去天台抽烟）",
        "effects": [{"type": "ENERGY", "value": 10}, {"type": "SUSPICION", "value": 25}],
        "log": "[WARNING] 你在天台躲了半小时。精力恢复了，但你上了 HR 的'不配合'名单。"
      }
    ]
  }
]
```

## 4. 结局文案 (Endings)

**数据结构**: 关联 PRD 5.5 节的 5 种结局。

```json
{
  "BE_DEATH": {
    "title": "系统崩溃：精力耗尽",
    "text": "你的视线开始模糊，心脏狂跳。倒下的那一刻，你甚至没来得及 Push 代码。醒来时你已经在 ICU，医生说你运气好。当然，公司按最低标准赔了你一点钱，前提是你签了自愿离职书。"
  },
  "BE_FIRED": {
    "title": "查无此人：绩效垫底",
    "text": "保安站在你身旁，看着你收拾纸箱。'能力不匹配'，这是 HR 给的最后判决。你看着自己被立即停用的内网账号，在这个寒冬，你带着“自愿离职”的屈辱被踢出了大厂大门。"
  },
  "GE_OFFER": {
    "title": "金蝉脱壳：拿到 Offer",
    "text": "邮件弹出的那一刻，你如释重负。薪资涨了 30%，而且不打卡。当部门宣布裁员名单时，你笑着把准备好的离职信拍在了主管桌上，潇洒转身。"
  },
  "NE_PEACE": {
    "title": "和平分手：N+1 跑路",
    "text": "第30天，靴子落地。你被优化了。但因为你平时表现不错，没留把柄，公司痛快地给了 N+2。拿着这笔钱，你决定先去大理躺平几个月，大厂？狗都不来。"
  },
  "HE_KING": {
    "title": "内卷之王：活到最后",
    "text": "你是唯一的幸存者。你超额完成了所有 KPI，抗住了所有黑锅。老板在全员会上点名表扬了你。你成功拿到了一张奖状和接下来5年一签的劳动合同——前提是你接下来要一个人干三个人的活。你赢了，但你真的赢了吗？"
  }
}
```

## 5. 日间修饰符 (Day Modifiers)

**数据文件**: `assets/data/modifiers.json` — 12个修饰符

```typescript
interface DayModifier {
  id: string;           // 如 "MOD_BOSS_AWAY"
  label: string;        // 显示名
  description: string;  // 描述
  effects: {
    energyMultiplier?: number;        // 精力消耗倍率
    kpiMultiplier?: number;           // KPI收益倍率
    interviewMultiplier?: number;     // 面试收益倍率
    suspicionMultiplier?: number;     // 怀疑度增长倍率
    slackEnergyBoost?: number;        // SLACK额外精力
    slackSuspicionBoost?: number;     // SLACK额外怀疑度
    settlementDrainBonus?: number;    // 结算额外精力扣减
  };
  minDay?: number;      // 最早出现天数
  maxDay?: number;      // 最晚出现天数
  weight: number;       // 权重
}
```

## 6. 打断事件 (Interruptions)

**数据文件**: `assets/data/interruptions.json` — 8个打断事件

```typescript
interface Interruption {
  id: string;
  title: string;
  description: string;
  effects: { energy?: number; kpi?: number; interview?: number; suspicion?: number };
  log: string;
  minDay?: number;
  weekendExcluded?: boolean;
}
```

## 7. 怀疑度压力事件 (Pressure Events)

**数据文件**: `assets/data/pressure-events.json` — 6个压力事件

```typescript
interface PressureEvent {
  id: string;
  title: string;
  description: string;
  effects: { energy?: number; kpi?: number; interview?: number; suspicion?: number };
  log: string;
  minSuspicion: number;
  weight: number;
}
```

## 8. 状态条件 (Status Conditions)

**数据文件**: `assets/data/status-conditions.json` — 8个条件（4 buff + 4 debuff）

```typescript
interface StatusCondition {
  id: string;
  name: string;
  type: 'buff' | 'debuff';
  priority: number;
  triggers: { stat: string; operator: '>=' | '<='; value: number }[];
  effects: {
    kpiGainMultiplier?: number;
    energyCostMultiplier?: number;
    suspicionGainMultiplier?: number;
    interviewGainMultiplier?: number;
    allGainMultiplier?: number;
  };
  icon: string;
  tooltip: { title: string; effect: string; flavor: string };
}
```

## 9. 技能树 (Skills)

**数据文件**: `assets/data/skills.json` — 12个技能，4分支x3层

```typescript
interface SkillDef {
  id: string;           // 如 "ENERGY_T1"
  name: string;
  branch: string;       // "energy" | "tech" | "social" | "interview"
  tier: number;         // 1, 2, 3
  cost: number;         // 成长点消耗
  requires: string | null;  // 前置技能 ID
  effects: Record<string, number>;  // 被动效果
  icon: string;
  description: string;
  unlocksAction?: string;   // 解锁的行动 ID
  unlocksEvent?: string;    // 解锁的隐藏事件 ID
  enablesAction?: string;   // 启用的行动 ID
}
```

## 10. 事件分类 (Event Categories)

**数据文件**: `assets/data/event-categories.json` — 4个分类，映射不同背景图

```json
{
  "daily_work": { "label": "日常搬砖", "background": "/backgrounds/daily-work.png", "events": ["EV_001", ...] },
  "office_politics": { "label": "职场暗流", "background": "/backgrounds/office-politics.png", "events": ["EV_002", ...] },
  "tech_crisis": { "label": "技术危机", "background": "/backgrounds/tech-crisis.png", "events": ["EV_003", ...] },
  "personal_growth": { "label": "个人突围", "background": "/backgrounds/personal-growth.png", "events": ["EV_009", ...] }
}
```

---

## Current Implementation Reconciliation (2026-05-30)

This section is authoritative for current data/content behavior and supersedes stale historical counts or paths elsewhere in this file.

- Flutter content path is `assets/data/*.json`; do not use old `src/data/*` paths for current work.
- Current data files: actions, events, openings, endings, modifiers, interruptions, pressure events, status conditions, skills, and event categories.
- `actions.json`: 12 actions, including 4 core actions and 8 conditional/skill-gated actions.
- `events.json`: 65 events total, 14 high-risk events, and 5 QTE events (`EV_061`-`EV_065`).
- Every `GameEvent` must parse with exactly two `options`; QTE events still keep these options for schema compatibility.
- QTE event effects are driven by `qteConfig.effects` for `perfect`, `good`, and `miss` results.
- `endings.json` is the runtime source for ending title/text. `EndingScreen` reads it through `GameData.endings`.
- `event-categories.json` maps normal event IDs to four thematic background categories; QTE rendering uses `assets/backgrounds/QTE.png` inside `QteGame`.
