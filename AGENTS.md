# AGENTS.md — Frontend Survival (Flutter 版)

This file provides mandatory context and rules for AI coding agents working on this project.
Read it in full before making any changes.

---

## 1. Source-of-Truth Hierarchy

When documents conflict, **the higher-priority document wins.**

### 1.1 Priority Order

| Priority | Document | Role | Modification Rule |
|----------|----------|------|-------------------|
| **1 (highest in /docs)** | `docs/PRD.md` | Core product requirements: game rules, mechanics, UX expectations | **STRICT APPROVAL REQUIRED** (see §1.3) |
| 2 | `docs/DOC_AUDIT.md` — Active Patches | Overrides and corrections to other docs | Self-modifying (append new patches) |
| 3 | `docs/TECH_ARCH.md` | Implementation spec: state model, state machine, algorithms, directory structure, hard constraints | Regular improvement allowed |
| 4 | `docs/GAME_CONTENT.md` | Static data schemas and seed data (actions, events, openings, endings) | Regular improvement allowed |
| 5 | `docs/UI_DESIGN_SYSTEM.md` | Visual language, color tokens, layout proportions, component specs | Regular improvement allowed |

**Key distinction**: PRD.md is the **highest-priority document within /docs** for determining *what* the game should do. DOC_AUDIT.md is highest for *corrections* — it acts as a patch layer that overrides all other docs when conflicts exist.

### 1.2 Read-Before-Code Rule (Mandatory)

Before writing any runtime code, you MUST:
1. Read `docs/DOC_AUDIT.md` Active Patches section first (for known corrections)
2. Read the relevant `docs/PRD.md` sections (for core requirements)
3. Read the relevant `docs/TECH_ARCH.md` sections (for implementation constraints)

If you skip this and produce code that contradicts a known patch or PRD requirement, your change will be rejected.

### 1.3 PRD.md Modification Protocol (STRICT)

**PRD.md is the core requirements document. Treat it as read-only unless explicitly authorized.**

| Action | Allowed? | Process |
|--------|----------|---------|
| **Substantive modification** (adding/removing/changing game mechanics, rules, endings, core mechanics) | NO without explicit user approval | MUST propose the change to the user first. Wait for explicit approval before editing. |
| **Minor corrections** (typos, formatting, clarifying ambiguous wording without changing meaning) | Yes | Allowed without approval. Document the change in your handoff. |
| **Adding cross-references** (linking to TECH_ARCH sections, etc.) | Yes | Allowed without approval. |

---

## 2. Project Overview

An Android mobile text resource-management game themed around surviving a tech-company layoff cycle. Pure client-side — no backend, no accounts, no API calls. Landscape orientation, terminal-style HUD layout.

**Tech stack**: Flutter · Dart · Riverpod (state) · SharedPreferences (persist) · audioplayers · lucide_icons · google_fonts · Flutter Animation (Framer Motion equivalent)

**Deployment**: Android APK.

---

## 3. Repository Map (Current Structure)

```
/
├── AGENTS.md                 ← You are here
├── TESTING_GUIDE.md          ← Automated testing guide
├── docs/
│   ├── PRD.md                ← Product requirements (HIGHEST PRIORITY in /docs)
│   ├── DOC_AUDIT.md          ← Conflict arbitration & active patches
│   ├── TECH_ARCH.md          ← Technical architecture (Flutter edition)
│   ├── UI_DESIGN_SYSTEM.md   ← Visual design system (Flutter edition)
│   ├── GAME_CONTENT.md       ← Data schemas & seed data
│   └── MIGRATION_PLAN.md     ← Web → Flutter migration plan (20 milestones)
├── lib/
│   ├── main.dart             ← App entry point (GameData.init + runApp)
│   ├── app.dart              ← MaterialApp + theme
│   ├── state/
│   │   ├── game_notifier.dart    ← Riverpod Notifier (GameState + all actions)
│   │   ├── audio_notifier.dart   ← Riverpod Notifier (AudioState, NOT persisted)
│   │   ├── theme_provider.dart   ← GameTheme + Riverpod Provider (Dark/Light/Danger)
│   │   └── providers.dart        ← gameProvider + audioProvider
│   ├── models/
│   │   ├── game_state.dart       ← GameState class (24 fields, copyWith, fromJson/toJson)
│   │   ├── action_def.dart       ← ActionDef (12 actions)
│   │   ├── game_event.dart       ← GameEvent / EventOption / EventEffect
│   │   ├── log_entry.dart        ← LogEntry + LogType enum
│   │   ├── ending_type.dart      ← GamePhase + EndingType enums
│   │   └── qte_config.dart       ← QteConfig + QteResult enum
│   │   ├── action_stats.dart     ← ActionStats counters
│   │   ├── event_category.dart   ← EventCategory (4 categories → background images)
│   │   ├── day_modifier.dart     ← DayModifier (12 modifiers)
│   │   ├── interruption.dart     ← Interruption (8 events)
│   │   ├── pressure_event.dart   ← PressureEvent (6 events)
│   │   ├── status_condition.dart ← StatusCondition (8 buffs/debuffs)
│   │   ├── skill_def.dart      ← SkillDef (12 skills, 4×3)
│   │   └── audio_state.dart    ← AudioState model
│   ├── logic/
│   │   ├── game_loop.dart      ← Phase transition validation
│   │   ├── endings.dart        ← checkDailyEnding, checkFinalEnding
│   │   ├── events.dart         ← sampleEvent algorithm
│   │   ├── action_pool.dart    ← sampleActionPool (dynamic 4-action draw)
│   │   ├── action_resolver.dart ← Full 6-step effect chain
│   │   └── status_evaluator.dart ← computeActiveStatuses
│   ├── data/
│   │   └── game_data.dart      ← JSON loader (10 data types, sync getters)
│   ├── services/
│   │   ├── save_service.dart   ← SharedPreferences save/load/clear
│   │   └── audio_manager.dart  ← audioplayers singleton
│   ├── theme/
│   │   ├── colors.dart         ← AppColors (cyberpunk palette)
│   │   ├── typography.dart     ← AppFonts (Share Tech Mono + Fira Code)
│   │   ├── app_theme.dart      ← ThemeData
│   │   └── neon_styles.dart    ← NeonStyles (glow text/box builders)
│   ├── screens/
│   │   ├── game_screen.dart       ← Landscape 3-layer layout + phase routing
│   │   ├── title_screen.dart      ← Matrix rain + title + NEW GAME/CONTINUE/GUIDE
│   │   ├── tutorial_screen.dart   ← Full-screen gameplay manual overlay
│   │   ├── ending_screen.dart     ← Glitch reveal + survival report
│   │   └── video_intro_screen.dart ← Full-screen intro video (NEW GAME only)
│   ├── utils/
│   │   ├── clamp.dart             ← Int clamp helper
│   │   └── weekend.dart           ← Weekend day detection
│   └── widgets/
│       ├── matrix_rain.dart    ← Matrix digital rain
│       ├── typewriter_text.dart ← Timer-based typewriter
│       ├── top_bar.dart        ← HUD top bar (compact 28px)
│       ├── sidebar.dart        ← LeftDatePanel + RightStatsPanel
│       ├── editor.dart         ← Phase-specific content (2×2 action grid)
│       ├── terminal_widget.dart ← Terminal log display
│       ├── week_review.dart    ← Skill tree purchase modal
│       ├── animated_number.dart ← Animated stat display
│       ├── stress_fx.dart      ← Low-energy red pulse
│       ├── shake_widget.dart   ← High-risk event shake
│       ├── qte_game.dart       ← QTE mini-game widget
│       └── qte_result_overlay.dart ← QTE result overlay (particles/pulse/taunt)
├── assets/
│   ├── data/                   ← 10 JSON data files
│   ├── backgrounds/            ← 8 phase/event background PNGs
│   ├── video/                  ← Intro video (intro.mp4)
│   └── audio/bgm/ & sfx/       ← BGM (3 mp3) + SFX (5 files: ogg/wav)
├── test/
│   ├── logic/                  ← Pure logic unit tests
│   ├── models/                 ← Data model serialization tests
│   ├── data/                   ← JSON integrity tests
│   ├── state/                  ← Notifier action tests
│   ├── services/               ← SaveService tests
│   └── integration/            ← Full game loop + balance tests
└── pubspec.yaml                ← Dependencies + assets declaration
```

**Rule**: Never create files outside this structure without explicit instruction. Pure logic in `lib/logic/`, state in `lib/state/`, data in `lib/data/`, services in `lib/services/`.

---

## 4. Mandatory Rules

These rules are non-negotiable. Violating any of them is a defect, regardless of whether the code "works."

### 4.1 State Clamp

Every write to `energy`, `kpi`, `interview`, or `suspicion` MUST be wrapped in `clamp()`:

```dart
int clamp(int val, {int min = 0, int max = 100}) {
  if (val < min) return min;
  if (val > max) return max;
  return val;
}
```

- **Forbidden**: `state = state.copyWith(energy: state.energy - 10);` (without clamp)
- **Required**: `state = state.copyWith(energy: clamp(state.energy - 10));`
- This applies in: GameNotifier actions, event effects, settlement logic, action resolver effects. No exceptions.
- Defined in: `lib/utils/clamp.dart`

### 4.2 State Machine Phases

The game has exactly 7 phases. Transitions are strictly ordered — no skipping, no reversing:

```
TITLE → (Intro Video, NEW GAME only) → OPENING → MORNING → AFTERNOON → EVENT → SETTLEMENT → ENDING
                                      └── (loop back to OPENING if no ending)
```

| From | To | Trigger |
|------|----|---------|
| TITLE | OPENING | `startNewGame()` or `continueGameFrom()` |
| OPENING | MORNING | `skipOpening()` |
| MORNING | AFTERNOON | `selectAction()` (25% chance of interruption) |
| AFTERNOON | EVENT | `selectAction()` |
| EVENT | SETTLEMENT | `selectEventOption()` or `triggerEvent()` with null event |
| SETTLEMENT | ENDING | Ending triggered (daily or final check) |
| SETTLEMENT | OPENING | No ending → day++, earn skill points at day 7/14/21 |
| ENDING | TITLE | `restart()` |

Validation: `lib/logic/game_loop.dart` — `isValidTransition(from, to)` and `LEGAL_TRANSITIONS` map.

**Forbidden behaviors**:
- Jumping from MORNING/AFTERNOON directly to ENDING (ending checks ONLY happen in SETTLEMENT)
- Skipping the OPENING phase
- Running SETTLEMENT logic across multiple frames (must be synchronous within `runSettlement()`)

### 4.3 Settlement Logic Order (Patch-010, Patch-011)

This is a known danger area. Two patches have corrected previous errors here.

```dart
// SETTLEMENT phase — EXACT execution order:
// 1. Apply daily energy drain: energy = clamp(energy - 5)
// 2. Run checkDailyEnding() — ALL days, INCLUDING Day 30
// 3. ONLY IF checkDailyEnding() returns null AND day === 30:
//    Run checkFinalEnding()
// 4. If ending triggered → phase = ENDING; EndingScreen clears save after reveal animation
// 5. If no ending → day++, savedAt = DateTime.now(), phase = OPENING; GameScreen saves post-frame
```

**Patch-010 correction**: Day 30 MUST run `checkDailyEnding` first. It is NOT a mutually exclusive branch with `checkFinalEnding`.

**Patch-011 ruling**: BE_FIRED on Day 30 uses the catch-all "none of the above" logic from PRD §5.4 priority list.

Implemented in: `lib/state/game_notifier.dart` → `runSettlement()` and `lib/logic/endings.dart`.

### 4.4 Data-Code Separation

- **Game content** (event text, opening lines, action effects, ending text) lives in `assets/data/*.json`, sourced from `docs/GAME_CONTENT.md`.
- **Components** read from data files via `GameData` (`lib/data/game_data.dart`). They MUST NOT contain hardcoded game strings or numeric constants.
- **Action effects** are defined in data. Components and Notifier actions reference them by ID, not by inline values.

### 4.5 Save System Rules

- Storage key: `frontend-survival-save` (SharedPreferences) — no other key allowed
- Save triggers: after SETTLEMENT produces a no-ending OPENING state; `GameScreen` calls `SaveService.save()` post-frame
- Save clear: `EndingScreen` calls `SaveService.clear()` after the glitch/reveal animation completes
- Version check: if saved `version` ≠ current code version → discard save, treat as new game
- Save content: must persist all fields in `GameState` class (see TECH_ARCH §2.1)
- Implemented in: `lib/services/save_service.dart`

### 4.6 Audio Rules

- Audio state (`AudioNotifier`) is a SEPARATE Riverpod Notifier — never mixed into `GameState`
- Audio state is NOT persisted (resets on each app launch)
- All playback through `lib/services/audio_manager.dart` singleton — never `AudioPlayer()` in widgets
- BGM: 3 tracks (title/daily/tension), crossfade 1s on scene change, `ReleaseMode.loop`
- SFX: 5 sounds (click/event/alert/glitch/success), triggered via ID→filename mapping table
- SFX Player uses `AndroidAudioFocus.none` — must NOT steal focus from BGM
- BGM scene logic lives in `game_screen.dart` `_syncBgm`, NOT in AudioManager
- Missing audio files: game continues silently (try-catch in AudioManager)

### 4.7 UI Rules (from UI_DESIGN_SYSTEM.md — Cyberpunk Terminal Theme)

- **Theme**: Cyberpunk Terminal — deep black `AppColors.bgDeep` with neon glow effects
- **Fonts**: Share Tech Mono (HUD/titles) + Fira Code (body/code), via `AppFonts.hud()` / `AppFonts.code()`
- **Orientation**: LANDSCAPE only (locked in `main.dart`)
- **Icons**: `lucide_icons` package (`LucideIcons.*`) only — NO emojis as UI icons
- **Layout**: 3 vertical layers — TopBar (h=28) → Row(LeftDatePanel 72dp | Editor Expanded | RightStatsPanel 150dp) → Collapsible Terminal (72px when open)
- **LeftDatePanel**: Day number + /30 + 30-day timeline dots (4 per row, 8 rows)
- **RightStatsPanel**: 4 stat bars (ENERGY/KPI/INTERVIEW/SUSPICION) vertical + Buff/Debuff chips (click for tooltip) + phase label
- **Action grid**: 2×2 `GridView.count`, equal-size cards, 16dp spacing
- **Action cards**: Dark bg `#1E1E1E`, 12dp radius, title+description+stat pills at bottom, streak badge on overlay
- **Terminal**: Collapsible via toggle bar, 72px when open, hidden when collapsed
- **Terminal logs**: `AppFonts.codeFamily`, prefix `[D##] [TYPE]`, neon color per log type
- **Progress bars**: `LinearProgressIndicator` with `AlwaysStoppedAnimation`; critical (<20) = red; warning (<40) = amber; inverted for suspicion (≥80 = red, ≥60 = amber)
- **Typewriter effect**: `TypewriterText` widget, ~30ms per character, skippable via tap, cyan cursor
- **Bad Ending**: Two-phase — glitch text (magenta+cyan shadow offset) then reveal
- **High-risk events**: Red `BoxShadow` glow + `ShakeWidget`
- **Stress FX**: `StressFx` widget when energy < 20 (red inner shadow pulse)
- **Title screen**: `MatrixRain` CustomPainter + ASCII art + `TweenAnimationBuilder` flicker
- **Glassmorphism**: `GlassPanel` widget — `RepaintBoundary → ClipRRect → BackdropFilter(blur sigma=12) → Container(theme.colors.glassOverlay, border theme.colors.glassBorder)`. Applied to Opening, Action Cards, Event, Interruption, Pressure panels. Colors vary per theme (Dark: black 0.5+white 0.15, Light: white 0.25+0.35, Danger: deep crimson 0.5+neonRed 0.5).
- **Phase transitions**: `AnimatedSwitcher(300ms)` with `transitionBuilder` for `ScaleTransition(0.9↔1.0) + FadeTransition` on both enter and exit.
- **Background crossfade**: `AnimatedSwitcher(500ms, ValueKey(bgPath))` on background images. 8 images precached in `GameData.init()`, including `QTE.png`.
- **Enter animations**: `_PopIn` widget (configurable delay, default 300ms) for scale+fade pop-in. Action cards use `delayMs: 500`.
- **Press-scale + haptic**: All buttons use `AnimatedScale(100ms, easeInOutCubic)` + `HapticFeedback.lightImpact()`. Scale ratio: action cards 0.95, event options 0.97, others 0.93.
- **Overscroll prevention**: ALL scrollable areas use `ClampingScrollPhysics()` + `ScrollConfiguration(overscroll: false)`.
- **Terminal**: Auto-scroll via `ScrollController.animateTo()`. Header merged with toggle bar: `[▼] LOG // CH0 (##) TERMINAL ▼`.
- **Skill undo**: `refundSkill()` in `GameNotifier`. WeekReview `_pendingUndoSkillId` double-tap to undo.
- **Status panel animations**: `_RightStat` breathing effect (warning slow 1.5s, danger fast 0.7s) + `_FloatingDeltaText` popup + progress bar `TweenAnimationBuilder`.
- **Buff/skill chips**: `TweenAnimationBuilder(Curves.elasticOut, 350ms)` spring-in. Wrapped with `Wrap` for horizontal flow. Middle section scrollable via `Expanded(SingleChildScrollView)`.

---

## 5. High-Risk Areas

Changes in these areas require extra caution and broader validation:

### 5.1 Settlement Phase Logic
- Involves multi-step arithmetic with clamp, priority-ordered checks, and versioned patches
- **Required**: Test every branch (BE_DEATH, BE_FIRED, GE_OFFER, NE_PEACE, HE_KING) independently
- **Required**: Test Day 30 specifically with combinations that could trigger daily-ending AND final-ending
- Covered by: `test/logic/endings_test.dart`, `test/state/game_notifier_test.dart`, `test/integration/full_game_loop_test.dart`

### 5.2 Event Sampling Algorithm
- Weighted random with 50% decay on repeated events, 10% null chance
- **Required**: Verify no empty-pool crashes, correct weight calculation
- Covered by: `test/logic/events_test.dart`

### 5.3 Save/Load Round-Trip
- `GameState.toJson()` / `GameState.fromJson()` must preserve exact state
- **Required**: Verify save → load → save produces identical state
- **Required**: Verify version mismatch correctly discards stale saves
- Covered by: `test/services/save_service_test.dart`, `test/integration/save_roundtrip_test.dart`

### 5.4 Action Effect Chain
- 6-step chain: streak → spot check → modifier → weekend → status → skills
- **Required**: Verify correct multiplier stacking order
- **Required**: Verify clamp applied at final step only
- Covered by: `test/logic/action_resolver_test.dart`

### 5.5 Game Content Data
- Any mismatch between JSON data and Dart class fields causes runtime errors
- **Required**: Verify all event effect types match `EventEffect.type`
- **Required**: Verify all action IDs referenced in code match data IDs
- Covered by: `test/models/models_test.dart`, `test/data/data_integrity_test.dart`

---

## 6. Open Risks & Unresolved Items

| ID | Source | Status | Description |
|----|--------|--------|-------------|
| Patch-006 | DOC_AUDIT.md | **Mitigated** | Numerical balance: pure "study + slack" rotation reaching interview >= 80 too quickly. Partially mitigated by F04 (streak penalty + spot check) and F02 (suspicion gate on GE_OFFER). Remaining risk: exact balance needs playtest validation. |
| Title version | Code | **Fixed** | `title_screen.dart` now shows v1.3.0 matching `GameState.gameVersion`. |
| Audio files | Assets | **Fixed** | BGM (3 mp3) and SFX (5 ogg/wav) files present in `assets/audio/`. AudioManager fully functional. |
| Launcher identity | Android | **Fixed** | Launcher label is `Frontend Survival`; mipmap launcher icons are generated from `tmp_icon/icon.png`. |

---

## 7. Validation & Testing Expectations

### 7.1 Validation Depth Must Match Risk

Surface-level testing is insufficient for changes to:
- Settlement logic
- State machine transitions
- Save/load round-trips
- Numerical calculations involving clamp

For these areas, you MUST test **edge cases**, not just happy paths.

### 7.2 Minimum Test Coverage by Area

| Area | What to Test |
|------|-------------|
| `clamp()` | 0, 100, -1 (underflow), 101 (overflow), 50 (normal) |
| State machine | Every legal transition; rejection of illegal transitions |
| Settlement | Each ending condition independently; Day 30 with daily+final overlap; energy=0 after drain; kpi=0 after drain |
| Event sampling | Empty pool → null; 10% null chance; weight decay after first trigger |
| Save/Load | Full round-trip; version mismatch → discard; ENDING → clear save |
| Action prerequisites | FIX_BUG enabled when energy > 20; disabled when energy ≤ 20 |

### 7.3 Test Infrastructure

**Current state**: 248 tests passing across 15 test files.
**Framework**: `flutter test` (package:test + package:flutter_test).
**Commands**:
- `flutter test` — run all tests
- `flutter test test/logic/` — logic tests only
- `flutter analyze` — static analysis (must return zero errors)

When adding unit tests:
- Place test files adjacent to source: `lib/logic/endings.dart` → `test/logic/endings_test.dart`
- Use `ProviderContainer` for testing Riverpod Notifiers
- Use `SharedPreferences.setMockInitialValues({})` for testing SaveService

---

## 8. Task Completion Standards

Before marking any task as complete, you MUST:

1. **Confirm source-of-truth compliance**: Does your code match TECH_ARCH and all Active Patches in DOC_AUDIT?

2. **Run validation appropriate to the change scope**:
   - Logic changes → unit tests for the affected functions
   - State changes → Notifier action tests
   - Data changes → type/interface consistency check
   - UI changes → `flutter analyze` + manual render verification

3. **Report honestly in your handoff**: what changed, why, what was verified, how, what was NOT verified, remaining risks.

4. **Do NOT**: claim "all tests pass" when no tests exist; mark complete based on "theoretically should work"; skip edge-case validation for high-risk areas; hide known issues.

---

## 9. Do Not

- **Do not** hardcode game content (event text, action effects, openings) in widget or logic files — use `GameData` and `assets/data/`
- **Do not** add new game mechanics not defined in PRD — propose them as DOC_AUDIT patches instead
- **Do not** make substantive changes to PRD.md without explicit user approval — see §1.3
- **Do not** use emoji as UI icons — use `lucide_icons` (`LucideIcons.*`) exclusively
- **Do not** use custom hex colors outside the cyberpunk palette defined in `lib/theme/colors.dart`
- **Do not** create new Riverpod Notifiers without justification — current mutable Notifiers are `gameProvider` and `audioProvider`; `themeProvider` is a read-only derived Provider.
- **Do not** bypass clamp for "small" or "safe" value changes
- **Do not** trigger ending checks outside SETTLEMENT phase
- **Do not** resolve Patch-006 (balance issue) without explicit user instruction
- **Do not** add runtime dependencies without checking against TECH_ARCH §1 tech stack
- **Do not** use `dynamic` casts when the proper Dart model class is available
- **Do not** leave empty catch blocks
- **Do not** generate unnecessary files or directories beyond the repository map (§3)
- **Do not** remove `RepaintBoundary` from `GlassPanel` — it prevents BackdropFilter from being discarded during scroll/touch
- **Do not** remove `ClampingScrollPhysics()` or `overscroll: false` from scroll views — they prevent overscroll from breaking BackdropFilter
- **Do not** change `GlassPanel` blur sigma (12), themed overlay, or themed border — these are the global glassmorphism standard
- **Do not** use `Opacity(opacity: 0)` anywhere inside a BackdropFilter ancestor — use `0.01 + 0.99 * value` to keep the filter layer alive
- **Do not** animate BackdropFilter sigma directly for fade-in — use the `_PopIn` wrapper which handles opacity correctly
- **Do not** hardcode `Colors.black.withValues(alpha: 0.4)` or `Colors.white.withValues(alpha: 0.1)` for glass panels — use `theme.colors.glassOverlay` / `theme.colors.glassBorder` from `themeProvider`
- **Do not** manually switch themes — theme is a pure derivation of GameState via `GameTheme.compute()`
- **Do not** use `Container(color: Color(0xFF...))` for themed backgrounds — use `AnimatedContainer(duration: 500ms)` with `theme.colors.*`

---

## 10. Patch Management Protocol

When you discover a conflict, gap, or ambiguity in the documentation:

1. **Do not** silently resolve it in code
2. **Do not** modify PRD.md, TECH_ARCH.md, or other docs directly
3. **Do** add a new Patch entry to `docs/DOC_AUDIT.md` Active Patches section:
   - Patch number: next sequential (currently Patch-F06+)
   - Date
   - Description of the conflict/gap
   - Resolution or "Open" status
   - If resolved: which document sections were updated
4. **Only then** implement the code aligned with the patch ruling

---

## 11. Commands

| Command | Purpose | Notes |
|---------|---------|-------|
| `flutter run` | Launch on connected device/emulator | Use during UI iteration. |
| `flutter build apk` | Build Android release APK | Use for final verification |
| `flutter analyze` | Static analysis | Run before committing. Must return zero errors. |
| `flutter test` | Full test suite (248 cases) | Run after logic changes. |

Do NOT fabricate commands that don't exist.

---

## 12. Language Note (语言说明)

- Project: Core documentation is in English for compatibility with AI coding tools
- Game Content: `assets/data/*.json` files use Chinese (narrative text)
- Code Comments: Keep in English to match the dev toolchain
