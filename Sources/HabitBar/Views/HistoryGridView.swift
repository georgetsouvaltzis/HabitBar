import HabitBarCore
import SwiftUI

struct HistoryGridView: View {
    let habit: Habit
    @Bindable var model: HabitBarModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var displayedMonth = Calendar.current.startOfMonth(containing: Date())

    private let monthColumns = Array(repeating: GridItem(.fixed(24), spacing: 4), count: 7)
    private let monthGridWidth: CGFloat = 192

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("This Week")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Spacer()
                Text("\(model.stats(for: habit).completedThisWeek) of \(model.stats(for: habit).dueThisWeek)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                ForEach(currentWeekDays, id: \.self) { day in
                    VStack(spacing: 4) {
                        Text(weekdayLabel(for: day))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(isToday(day) ? accent : .secondary)
                            .frame(width: 16)

                        dayCell(for: day)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(monthTitle)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Spacer()
                    HStack(spacing: 6) {
                        Button {
                            changeDisplayedMonth(by: -1)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .accessibilityLabel("Previous month")

                        Button {
                            changeDisplayedMonth(by: 1)
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .disabled(!canShowNextMonth)
                        .accessibilityLabel("Next month")
                    }
                    .buttonStyle(MonthNavigationButtonStyle(accent: accent))
                }

                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        ForEach(Weekday.mondayFirst) { weekday in
                            Text(weekday.shortTitle.prefix(1))
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                        }
                    }
                    .frame(width: monthGridWidth)

                    LazyVGrid(columns: monthColumns, spacing: 2) {
                        ForEach(monthDays, id: \.self) { day in
                            calendarDayCell(for: day)
                        }
                    }
                    .frame(width: monthGridWidth)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    @ViewBuilder
    private func dayCell(for day: Date) -> some View {
        if isFillable(day) {
            Button {
                withAnimation(.snappy) {
                    model.toggle(habit: habit, targetDate: day)
                }
            } label: {
                HistoryCell(state: displayState(for: day), accent: accent)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel(for: day))
            .accessibilityIdentifier(AccessibilityID.gridCell(
                habitID: habit.id.uuidString,
                day: isoDay(day)
            ))
        } else {
            HistoryCell(state: displayState(for: day), accent: accent)
                .frame(width: 24, height: 24)
                .accessibilityLabel(accessibilityLabel(for: day))
                .accessibilityIdentifier(AccessibilityID.gridCell(
                    habitID: habit.id.uuidString,
                    day: isoDay(day)
                ))
        }
    }

    @ViewBuilder
    private func calendarDayCell(for day: Date) -> some View {
        if isFillable(day) {
            Button {
                withAnimation(.snappy) {
                    model.toggle(habit: habit, targetDate: day)
                }
            } label: {
                MonthDayCell(
                    day: day,
                    state: displayState(for: day),
                    isInDisplayedMonth: isInDisplayedMonth(day),
                    isToday: isToday(day),
                    accent: accent
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel(for: day))
            .accessibilityIdentifier(AccessibilityID.gridCell(
                habitID: habit.id.uuidString,
                day: isoDay(day)
            ))
        } else {
            MonthDayCell(
                day: day,
                state: displayState(for: day),
                isInDisplayedMonth: isInDisplayedMonth(day),
                isToday: isToday(day),
                accent: accent
            )
            .accessibilityLabel(accessibilityLabel(for: day))
            .accessibilityIdentifier(AccessibilityID.gridCell(
                habitID: habit.id.uuidString,
                day: isoDay(day)
            ))
        }
    }

    private var currentWeekDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private var monthDays: [Date] {
        let calendar = Calendar.current
        let monthStart = displayedMonth
        let weekdayOffset = (calendar.component(.weekday, from: monthStart) + 5) % 7
        let gridStart = calendar.date(byAdding: .day, value: -weekdayOffset, to: monthStart) ?? monthStart
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var canShowNextMonth: Bool {
        displayedMonth < Calendar.current.startOfMonth(containing: Date())
    }

    private func changeDisplayedMonth(by offset: Int) {
        let calendar = Calendar.current
        let currentMonth = calendar.startOfMonth(containing: Date())
        let nextMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth) ?? displayedMonth
        displayedMonth = min(calendar.startOfMonth(containing: nextMonth), currentMonth)
    }

    private func isFillable(_ day: Date) -> Bool {
        if model.isTrackingDay(for: habit, date: day) {
            return true
        }

        if case .completed = model.dayState(for: habit, date: day) {
            return true
        }

        return false
    }

    private func displayState(for day: Date) -> HabitDayState {
        let state = model.dayState(for: habit, date: day)
        switch state {
        case .future, .offSchedule:
            return model.isTrackingDay(for: habit, date: day)
                ? .missed
                : .offSchedule
        default:
            return state
        }
    }

    private func accessibilityLabel(for day: Date) -> String {
        switch model.dayState(for: habit, date: day) {
        case .completed:
            "Completed"
        case .today:
            "Today"
        case .graceEligible, .missed:
            "Incomplete"
        case .future, .offSchedule:
            model.isTrackingDay(for: habit, date: day) ? "Incomplete" : "Off schedule"
        }
    }

    private func isoDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func weekdayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func isInDisplayedMonth(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: displayedMonth, toGranularity: .month)
    }

    private var accent: Color {
        Color(habitColor: habit.color, colorScheme: colorScheme)
    }
}

private struct MonthNavigationButtonStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .frame(width: 24, height: 24)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(accent.opacity(0.18), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}

private extension Calendar {
    func startOfMonth(containing date: Date) -> Date {
        dateInterval(of: .month, for: date)?.start ?? startOfDay(for: date)
    }
}

private struct MonthDayCell: View {
    let day: Date
    let state: HabitDayState
    let isInDisplayedMonth: Bool
    let isToday: Bool
    let accent: Color

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(fill)
                .overlay {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(stroke, lineWidth: strokeWidth)
                }

            Text(dayLabel)
                .font(.system(size: 9, weight: isToday ? .bold : .semibold))
                .monospacedDigit()
                .foregroundStyle(labelColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(width: 24, height: 24)
    }

    private var dayLabel: String {
        String(Calendar.current.component(.day, from: day))
    }

    private var labelColor: Color {
        if isToday {
            return .white
        }

        if !isInDisplayedMonth {
            return .secondary.opacity(0.45)
        }

        switch state {
        case .completed:
            return .white
        case .today, .graceEligible, .missed:
            return .primary
        case .future, .offSchedule:
            return .secondary
        }
    }

    private var fill: Color {
        switch state {
        case .completed:
            return accent
        case .today:
            return accent.opacity(0.28)
        case .graceEligible, .missed:
            return .secondary.opacity(0.16)
        case .future, .offSchedule:
            return .secondary.opacity(isInDisplayedMonth ? 0.06 : 0.035)
        }
    }

    private var stroke: Color {
        isToday ? accent : .secondary.opacity(0.08)
    }

    private var strokeWidth: CGFloat {
        isToday ? 1.4 : 0.6
    }
}

private struct HistoryCell: View {
    let state: HabitDayState
    let accent: Color

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 3)
                .fill(fill)
                .frame(width: 17, height: 17)
                .overlay {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(stroke, lineWidth: strokeWidth)
                }
        }
    }

    private var fill: Color {
        switch state {
        case .completed:
            accent
        case .today:
            accent.opacity(0.12)
        case .graceEligible, .missed:
            .secondary.opacity(0.16)
        case .future, .offSchedule:
            .secondary.opacity(0.06)
        }
    }

    private var stroke: Color {
        switch state {
        case .today:
            return accent
        case .completed, .graceEligible, .missed, .future, .offSchedule:
            return .clear
        }
    }

    private var strokeWidth: CGFloat {
        switch state {
        case .today:
            return 1.5
        default:
            return 0
        }
    }
}
