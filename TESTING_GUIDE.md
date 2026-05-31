# Flutter Testing Guide - Frontend Survival

Purpose: automated validation for the current Flutter game implementation.

Last updated: 2026-05-30

## Quick Commands

```powershell
cd C:\Users\y\Desktop\vibecoding\vibe2_flutter
flutter analyze
flutter test
flutter test --reporter expanded
flutter test test/logic/
flutter test test/state/
flutter test test/integration/
```

`flutter analyze` must return zero issues. The current full suite is **248 passing tests across 15 Dart test files**.

## Test Layout

```text
test/
  data/
    data_integrity_test.dart
  integration/
    balance_test.dart
    full_game_loop_test.dart
    save_roundtrip_test.dart
  logic/
    action_pool_test.dart
    action_resolver_test.dart
    endings_test.dart
    events_test.dart
    game_loop_test.dart
  models/
    models_test.dart
  services/
    save_service_test.dart
  state/
    audio_notifier_test.dart
    game_notifier_test.dart
  utils/
    clamp_test.dart
    weekend_test.dart
```

## Current Coverage Facts

- Data integrity checks 10 JSON files, 12 actions, 65 events, 14 high-risk events, 30 openings, and 5 endings.
- Model tests cover JSON parsing/serialization for actions, events, modifiers, interruptions, pressure events, statuses, skills, logs, action stats, and `GameState`.
- Logic tests cover clamp boundaries, weekend detection, legal/illegal phase transitions, ending priority, event sampling, action pool construction, and the 6-step action resolver.
- State tests cover `GameNotifier`, `AudioNotifier`, settlement, helpers, action selection, QTE-adjacent event flow, and all five endings.
- Integration tests cover full day loops, save/load round-trips, version mismatch discard, balance expectations, suspicion pressure, weekly review, skills, and interruptions.

## Important Current Behaviors

- `startNewGame()` evaluates status conditions immediately. The initial state activates `TRUSTED` because suspicion starts at 20, so early action effects may already be status-modified.
- `startNewGame()` also adds the initial status log entry. Tests that append logs should assert against `logs.last` when they care about the newly added log.
- Day 30 settlement must run `checkDailyEnding()` first, then `checkFinalEnding()` only if no daily ending occurred.
- Save tests must use `SharedPreferences.setMockInitialValues({})`.
- QTE events keep exactly two fallback options in JSON for parser compatibility, while QTE result effects come from `qteConfig`.

## Adding Tests

- Pure calculations belong in `test/logic/`.
- Riverpod notifier behavior belongs in `test/state/` with a fresh `ProviderContainer`.
- Save/load behavior belongs in `test/services/` or `test/integration/` with mocked SharedPreferences.
- Cross-system gameplay scenarios belong in `test/integration/`.
