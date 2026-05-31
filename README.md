# Frontend Survival

Flutter/Android text resource-management game about surviving a tech-company layoff cycle. The launcher name is **Frontend Survival**.

## Current Status

- Flutter app, landscape Android target, pure client-side.
- Runtime version: `1.3.0+1`; save version: `GameState.gameVersion == 1.3.0`.
- Local persistence: `SharedPreferences` key `frontend-survival-save`.
- Content data: 10 JSON files in `assets/data/`.
- Events: 65 total, including 14 high-risk events and 5 QTE events.
- Backgrounds: 8 PNGs in `assets/backgrounds/`, all preloaded by `GameData.init()`.
- Tests: 248 automated cases across 15 Dart test files.

## Source Of Truth

Read these before changing runtime code:

1. `docs/DOC_AUDIT.md` active patches and overrides.
2. `docs/PRD.md` for product rules and game mechanics.
3. `docs/TECH_ARCH.md` for implementation constraints.
4. `AGENTS.md` for agent-specific rules.

The latest reconciliation patch is `docs/DOC_AUDIT.md` Patch-F18.

## Useful Commands

```powershell
flutter analyze
flutter test
flutter run -d <device_id>
flutter build apk --release
```

`flutter analyze` must report zero issues before handoff.
