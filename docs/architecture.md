# Architecture

Habit Bar is a SwiftPM-based macOS app with three main products:

- `HabitBar`: the macOS executable and SwiftUI UI.
- `HabitBarCore`: the domain library for models, rules, notification planning,
  and persistence contracts.
- `HabitBarUITestRunner`: a command-line UI smoke runner used by local scripts.

## Package Layout

```text
Sources/
  HabitBar/
    App/          App entrypoint and observable app model
    Services/     macOS notification scheduling adapter
    Stores/       sample data for UI testing
    Support/      UI helpers and accessibility identifiers
    Views/        SwiftUI views for the popover, cards, editor, settings
  HabitBarCore/
    Models/       Habit, entries, colors, schedule, theme, weekday
    Rules/        Habit rule engine, calendar helpers, notification planner
    Store/        Store protocol and JSON store implementation
  HabitBarUITestRunner/
    main.swift    Smoke-test executable
Tests/
  HabitBarCoreTests/
script/
  build_and_run.sh
  run_tests.sh
```

## Data Flow

`HabitBarModel` is the app-facing state owner. It loads a `HabitSnapshot` from a
`HabitStoreProtocol`, exposes active and archived habits to the views, delegates
stats and day-state calculations to `HabitRuleEngine`, and synchronizes local
notifications after saves.

Views should not calculate habit rules directly. They should ask the model for:

- `stats(for:)`
- `dayState(for:date:)`
- `isTrackingDay(for:date:)`

The model persists after every habit or entry mutation. Notification scheduling
is behind `NotificationScheduling` so command-line tests and non-bundled runs do
not touch `UNUserNotificationCenter`.

## Runtime Boundaries

- `HabitBarCore` must not depend on SwiftUI, AppKit, or UserNotifications.
- `HabitBar` may depend on SwiftUI, AppKit, and UserNotifications.
- Notification delivery should stay behind the scheduling service.
- Persistence should stay behind `HabitStoreProtocol`.
- Rule changes should be covered in `HabitBarCoreTests`.

## UI Testing Mode

`HabitBarModel(uiTesting: true)` uses in-memory sample data and a disabled
notification scheduler. The build script passes `-DUI_TESTING` for UI smoke
verification so the app launches with predictable state.
