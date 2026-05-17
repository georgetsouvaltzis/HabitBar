# Habit Rules

Habit Bar v1 presents habits as selected-day schedules. The editor defaults new
habits to Monday through Friday, and users can add or remove any day.

The core model still has legacy schedule cases for compatibility and tests, but
the app normalizes edited and loaded habits to selected weekdays for the v1 UI.

## Completion Entries

Habit progress is stored as `HabitEntry` records:

- `habitID`
- `targetDate`
- `completedAt`
- `source`

Entries are the source of truth. Streaks and percentages are derived from the
habit schedule plus entries.

## Day States

For selected-day habits:

- A completed date is shown as done.
- Today is actionable when it is a selected tracking day.
- Future selected tracking dates can be filled from the history grid.
- Off-schedule days are visible in the month grid but do not count toward
  completion or streaks.
- Archived habits do not evaluate as due.

V1 does not show separate visual markers for manual backfill. A click on a
visible selected day simply toggles that date.

## Weekly Completion

Weekly completion is calculated from the visible Monday-Sunday week:

- denominator: selected tracking days in the current week
- numerator: selected tracking days in the current week with completion entries
- off-schedule days are excluded

If no days are selected, weekly completion is `0%` with zero due days.

## Streaks

Current and best streaks count consecutive completed selected tracking days.
Off-schedule days do not break a streak.

Current streak is anchored to the real current day. If there is a missed selected
tracking day between the latest completed entry and today, the current streak
does not continue through older or future fills.

Best streak is the longest completed run in the evaluated history, including the
current run when it is the longest.

## Notifications

Notifications are local macOS reminders.

- Disabled reminders create no notification plans.
- Archived habits create no notification plans.
- Selected weekday habits schedule reminders for selected days.
- Reminders can create multiple notification plans: `1 hour before`, `Right on
  time`, `15 mins before`, and `30 mins before`.
- Selected weekday reminders are scheduled as concrete next occurrences so each
  lead time gets an exact pending notification request.
- Lead times that cross midnight schedule on the previous weekday or date.
- Notification message falls back to default copy when the custom message is
  empty.
- Foreground notifications still present a banner and play the default sound.
- The app only creates `UNUserNotificationCenter` in an app bundle runtime.
