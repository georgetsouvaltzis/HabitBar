# Habit Bar Goal

## Product Direction

Habit Bar is a native macOS, menu-bar-first habit tracker. The menu bar popover
is the primary daily experience: users should be able to review habits, mark
completion, inspect streaks, and interact with recent history without opening a
large dashboard.

The app may use small utility windows or sheets for create/edit flows when the
popover would become too cramped. A full dashboard is not required for the
initial version.

## V1 Scope

- Menu-bar-first macOS app.
- Create, edit, archive, delete, and restore habits.
- Habit properties:
  - name
  - icon
  - accent color
  - selected tracking days
  - notification settings
- Tracking days default to Monday-Friday, with Saturday and Sunday available
  as optional selected days. Any selected day can also be removed.
- Mark and unmark completion from the popover.
- Fill past or future selected tracking days from the history grid by clicking
  the day.
- Show current streak, best streak, this week, and mini history.
- Support local notifications with per-habit settings.
- Persist data across app restarts.
- Support light, dark, and system theme modes.
- Support per-habit accent colors that render safely in light and dark mode.

## Streak And Logging Rules

- Habits evaluate only on the selected tracking days.
- Off-schedule days do not break a streak.
- Archived habits stop evaluating streaks and do not schedule notifications.
- Streaks should be derived from habit entries and schedule rules, not treated
  as the primary source of truth.
- Older and upcoming selected tracking dates can be logged from the history
  grid with a simple click.
- Older logged dates do not need separate backfill labeling or markers in v1.
- Current streak is anchored to today's actual schedule state. Future fills do
  not hide a missed selected tracking day between today and the filled date.

## UI Direction

- The popover is the main app surface.
- The default view shows today's habits in a compact list.
- A habit row shows icon, name, completion state, streak, and reminder status.
- Expanded habit detail can show:
  - current streak
  - best streak
  - completion percentage
  - reminder time
  - this-week cells
  - compact month history grid
- History grid state should be visible by shape as well as color:
  - completed: habit accent fill
  - today: accent ring or focus border
  - open selected tracking day: neutral state
  - off-schedule day: disabled state
- Create/edit can use a compact utility sheet or window.
- In v1, create/edit is implemented as an inline popover editor mode.
- Settings should support theme mode:
  - system
  - light
  - dark
- There are no custom app themes in v1.
- Habit accent color customization should affect checkboxes, streak display,
  selected accents, and completed history cells.

## Notifications

- Notifications are local to macOS.
- Each habit can configure reminder settings.
- Reminder days should follow the selected tracking days by default.
- Archived habits must not schedule notifications.
- Notification scheduling should live behind a service abstraction so it can be
  tested without relying on system notification delivery.

## Definition Of Done

V1 is done when a user can:

- Run the app as a macOS menu bar app.
- Create a habit with a name, icon, accent color, selected tracking days, and
  reminder.
- Complete and undo today's habit completion from the popover.
- Log older and upcoming selected tracking dates from the history grid with a
  click.
- See current streak, best streak, this week, and mini history update correctly.
- Archive, restore, and delete habits.
- Restart the app without losing data.
- Use the app in light, dark, and system theme modes.
- See habit colors remain readable in both light and dark mode.
- Receive local reminders only when appropriate.
- Read project documentation under `docs/` for product scope, architecture,
  rules, UI direction, and development commands.

## Engineering Definition Of Done

- Habit and streak rules are covered by unit tests.
- Selected-day logging behavior is covered by unit tests.
- Notification scheduling decisions are testable through a service abstraction.
- Persistence is behind a store boundary rather than scattered through views.
- Critical UI controls have accessibility identifiers.
- UI tests cover the core flows:
  - launch/open popover
  - create habit
  - complete today
  - log a prior or upcoming day from the grid
  - edit habit
  - archive, restore, and delete
- App builds cleanly from the command line.
- Tests run from the command line.
- `docs/` stays in sync with the current app behavior when product or
  architecture decisions change.
- Source files stay focused and are split before becoming catch-all files.
- User-facing states are handled:
  - empty state
  - no notification permission
  - invalid form input
  - archived habit
  - long habit names
  - many habits
- Visual checks cover:
  - light mode
  - dark mode
  - compact popover sizing
  - habit accent color contrast
  - history grid states

## Non-Goals For V1

- iCloud sync.
- Accounts.
- iOS app.
- Advanced analytics dashboard.
- Custom app themes beyond system, light, and dark.
- Social or sharing features.
- Widgets.
