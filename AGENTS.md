# Repository Guidelines

## Project Structure & Module Organization

HabitBar is a SwiftPM macOS project. `Package.swift` defines three products:
`HabitBar`, `HabitBarCore`, and `HabitBarUITestRunner`.

- `Sources/HabitBar/`: SwiftUI macOS app, menu bar UI, services, resources.
- `Sources/HabitBarCore/`: models, rules, notification planning, store protocols.
- `Sources/HabitBarUITestRunner/`: command-line UI smoke runner.
- `Tests/HabitBarCoreTests/`: unit tests for core rules, colors, persistence, notifications.
- `docs/`: product, architecture, habit rules, UI design, development notes.
- `script/`: local build, run, and verification scripts.

Keep rule logic in `HabitBarCore`. Keep platform APIs such as SwiftUI, AppKit, and
UserNotifications in `HabitBar`.

## Build, Test, and Development Commands

- `swift build`: build all SwiftPM targets.
- `swift test`: run unit tests.
- `./script/build_and_run.sh`: build `dist/HabitBar.app`, kill any running
  `HabitBar`, and launch the app.
- `./script/build_and_run.sh --release`: build and run a release bundle.
- `./script/build_and_run.sh --verify-release`: verify the release bundle starts.
- `./script/build_and_run.sh --ui-smoke`: run the UI smoke flow.
- `./script/run_tests.sh`: run unit tests plus the UI smoke flow.

After manual app runs, use `pgrep -x HabitBar` and `pkill -x HabitBar` to inspect
or stop leftover app processes.

## Coding Style & Naming Conventions

Use Swift 5.10 conventions with 4-space indentation. Prefer small, focused files
and views. Name types with `UpperCamelCase`, methods and properties with
`lowerCamelCase`, and tests with descriptive `test...` names.

Add brief comments only for tricky or bug-prone logic. Keep accessibility
identifiers in `Sources/HabitBar/Support/AccessibilityID.swift` for controls used
by UI smoke tests.

## Testing Guidelines

Use Swift Testing/XCTest-style unit coverage under `Tests/HabitBarCoreTests`.
Add regression tests for rule, persistence, color, or notification planning
changes when practical. Rule changes should be proven in `HabitBarCoreTests`
before relying on visual behavior.

Use UI smoke verification for menu bar flows: launch, complete/undo, add, edit,
delete, archive, and restore.

## Commit & Pull Request Guidelines

Use Conventional Commits: `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, or
`test:`. Current history follows examples such as `feat: add Habit Bar app` and
`docs: document release build commands`.

Pull requests should include a short summary, tests run, linked issue if any,
and screenshots or screen recordings for visible UI changes.

## Agent-Specific Instructions

Before coding, read relevant docs in `docs/`. Do not overwrite unrecognized
changes; assume another agent made them. For user-visible behavior changes,
update docs or changelog-style notes where relevant.
