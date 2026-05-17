# UI Design

Habit Bar should feel like a compact native macOS menu bar utility. The popover
is the product surface, not a teaser for a larger dashboard.

## Popover

The primary popover target is `430 x 620`.

The hierarchy is:

1. Header with app title and section label.
2. Today summary metrics.
3. Habit list.
4. Expanded habit detail for the selected habit.
5. Footer actions when not editing.
6. Inline editor when creating or editing.

The footer is hidden while editing so the form can use the available space.

## Habit Cards

Habit cards should be dense and scannable:

- icon and habit name communicate identity
- accent color reinforces selected and completed states
- checkbox toggles today's completion
- streak and reminder state are visible without opening a dashboard
- expanded state shows metrics, week cells, and a compact month grid

Accent color should not flood the whole card. Use it for icon background,
selected border, important numbers, completion controls, and completed history
cells.

## History Grid

The expanded history grid is a compact month calendar:

- week starts on Monday
- grid includes leading dates from the previous month and trailing dates from
  the next month
- month header includes previous/next controls
- forward navigation is capped at the current month
- cells stay small and regular
- each cell shows only the date number
- completed selected tracking days use the habit accent fill
- today has a clear border
- off-schedule days are muted

The grid should remain understandable without large legends or dashboard-style
analytics.

## Inline Editor

The editor is a focused popover mode, not a nested modal card.

Required layout:

- centered `New Habit` or `Edit Habit` title in the popover header
- close button in the top-right
- full-width name field
- circular icon choices with selected accent ring
- preset color swatches with selected accent ring
- selected-day chips from Monday to Sunday
- reminder toggle aligned to the right
- Time row with compact hour/minute steppers and AM/PM controls
- Schedule row with multi-select reminder timing chips
- Notification row with message field
- helper text under Notification: `This is the notification message you'll receive.`
- Cancel and Save grouped at the bottom-right

Selected habit color should affect:

- icon selection
- selected day chips
- selected color rings
- reminder switch when enabled
- Save button

## Theme And Contrast

The app supports system, light, and dark mode. Use semantic colors and system
materials where possible. Habit colors should be adjusted or rendered so they
remain readable in both light and dark mode.

Avoid:

- dashboard-style cards inside cards
- decorative gradients or blobs
- large empty marketing sections
- truncated control labels in normal sample data
- blue system accent where the habit accent should be used
