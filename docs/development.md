# Development

Habit Bar is a SwiftPM macOS project.

## Build

```sh
swift build
```

## Run

```sh
./script/build_and_run.sh
```

The run script builds a local app bundle under `dist/HabitBar.app` and opens it.
It kills an existing `HabitBar` process before launching.
The bundle copies `Sources/HabitBar/Resources/AppIcon.icns` into
`Contents/Resources` and declares it as `CFBundleIconFile`.

Build and run the release bundle:

```sh
./script/build_and_run.sh --release
```

Verify the release bundle starts:

```sh
./script/build_and_run.sh --verify-release
```

## Tests

Run unit tests:

```sh
swift test
```

Run unit tests plus UI smoke flow:

```sh
./script/run_tests.sh
```

Run only the UI smoke flow:

```sh
./script/build_and_run.sh --ui-smoke
```

The verification modes install a trap that kills `HabitBar` when the script
exits. After manual runs, check and clean up with:

```sh
pgrep -x HabitBar
pkill -x HabitBar
```

## UI Smoke Coverage

The UI smoke runner is expected to cover:

- app launch and popover/window detection
- completing and undoing today
- adding a habit
- editing a habit
- deleting a habit
- archiving and restoring a habit

## Implementation Notes

- Keep rule logic in `HabitBarCore`.
- Keep SwiftUI views focused and split by surface.
- Add unit tests for habit rule changes before relying on visual behavior.
- Add accessibility identifiers for UI controls used by smoke tests.
- Avoid directly constructing `UNUserNotificationCenter` outside an app bundle.
