# TODO - Current Project Status

Last updated: 2026-05-30

All previously listed Flutter migration TODO items are complete. This file is now a status ledger for known implemented systems and remaining watch items.

## Implemented

- Android landscape Flutter app with launcher label `Frontend Survival`.
- Launcher icons generated from `tmp_icon/icon.png` into Android `mipmap-*` resources.
- Title screen, tutorial overlay, intro video, game screen, and ending screen.
- 7-phase state machine: `TITLE -> OPENING -> MORNING -> AFTERNOON -> EVENT -> SETTLEMENT -> ENDING`.
- Dynamic 4-action pool from 12 actions.
- 65 events total, including 14 high-risk events and 5 QTE events.
- QTE mini-game on fixed days Day 5/10/15/20/25 and by weighted event sampling.
- Day modifiers, interruptions, suspicion pressure events, status conditions, skill tree, and skill undo.
- Themed glass HUD with Dark/Light/Danger derived themes.
- BGM/SFX system with crossfade and Android audio focus configuration.
- SharedPreferences save/load/clear with version mismatch discard.
- 8 background PNGs preloaded through `GameData.init()`.
- 248 automated tests across 15 Dart test files.

## Watch Items

- Patch-006 balance risk remains mitigated but still needs real playtest validation.
- QTE timeline red conflict marker is reserved for future overlap; current QTE days and week-review days do not overlap.
- `lib/widgets/buff_bar.dart` and `lib/widgets/crt_overlay.dart` are retained legacy files and are not the active HUD path.

## Validation Baseline

```powershell
flutter analyze
flutter test
```

Current baseline: analyze has zero issues; all 248 tests pass.
