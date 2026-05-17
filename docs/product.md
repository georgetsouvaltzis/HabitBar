# Product

Habit Bar is a native macOS habit tracker built around the menu bar popover.
The popover is the primary product surface: users open it, review today's
habits, log progress, inspect recent history, and make small edits without
switching to a full dashboard.

## V1 Scope

- Menu-bar-first macOS app.
- Create, edit, archive, restore, and delete habits.
- Habit configuration:
  - name
  - icon
  - accent color
  - selected tracking days
  - local reminder
- Tracking days default to Monday through Friday.
- Saturday and Sunday can be added, and any weekday can be removed.
- Completion can be toggled for today and for visible history dates.
- History dates can be filled or unfilled with a direct click.
- Expanded month history can navigate backward and forward up to the current
  month.
- Streaks, weekly completion, and month history update from logged entries.
- Theme mode supports system, light, and dark.
- Habit accent color is reflected in selected editor controls, completion
  controls, streak emphasis, Save action, reminder switch, and history cells.

## Core User Flows

1. Open Habit Bar from the macOS menu bar.
2. Add a habit with a name, icon, color, selected days, and optional reminder.
3. Complete or undo today's habit from the popover.
4. Expand a habit to inspect current streak, best streak, weekly completion, and
   recent history.
5. Click older or upcoming visible selected days in the month grid to log or
   undo progress.
6. Navigate month history without leaving the expanded habit.
7. Edit habit details without leaving the popover.
8. Archive, restore, or delete habits.

## Non-Goals

- Accounts.
- iCloud sync.
- iOS app.
- Widgets.
- Social or sharing features.
- Dashboard-first analytics.
- Custom app themes beyond system, light, and dark.
- Complex schedule types in the v1 UI.
