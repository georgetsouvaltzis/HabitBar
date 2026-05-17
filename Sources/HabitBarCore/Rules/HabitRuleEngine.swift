import Foundation

public struct HabitRuleEngine: Sendable {
    public var habitCalendar: HabitCalendar

    public init(habitCalendar: HabitCalendar = HabitCalendar()) {
        self.habitCalendar = habitCalendar
    }

    public func isDue(habit: Habit, on date: Date) -> Bool {
        guard !habit.isArchived else { return false }
        let day = habitCalendar.startOfDay(for: date)
        let createdDay = habitCalendar.startOfDay(for: habit.createdAt)

        guard day >= createdDay else { return false }

        switch habit.schedule {
        case .daily, .weeklyQuota, .monthlyQuota:
            return true
        case .weekdays(let weekdays):
            return weekdays.contains(habitCalendar.weekday(for: day))
        case .interval(let everyDays, let startDate):
            guard everyDays > 0 else { return false }
            let distance = habitCalendar.daysBetween(startDate, day)
            return distance >= 0 && distance % everyDays == 0
        }
    }

    public func dayState(habit: Habit, entries: [HabitEntry], date: Date, referenceDate: Date) -> HabitDayState {
        let day = habitCalendar.startOfDay(for: date)
        let today = habitCalendar.startOfDay(for: referenceDate)

        if let entry = entry(for: habit.id, targetDate: day, entries: entries) {
            return .completed(entry.source)
        }

        if day > today {
            return .future
        }

        guard isDue(habit: habit, on: day) else {
            return .offSchedule
        }

        if day == today {
            return .today
        }

        if habit.allowsGrace, habitCalendar.daysBetween(day, today) == 1 {
            return .graceEligible
        }

        return .missed
    }

    public func completionSource(forTargetDate targetDate: Date, completedAt: Date) -> CompletionSource {
        let distance = habitCalendar.daysBetween(targetDate, completedAt)

        if distance == 0 {
            return .normal
        }

        if distance == 1 {
            return .grace
        }

        return .manualBackfill
    }

    public func stats(for habit: Habit, entries: [HabitEntry], referenceDate: Date, lookbackDays: Int = 120) -> HabitStats {
        let today = habitCalendar.startOfDay(for: referenceDate)
        let habitEntries = entriesForHabit(habit.id, entries: entries)
        let completedDays = Set(habitEntries.map { habitCalendar.startOfDay(for: $0.targetDate) })
        let latestCompletedDay = completedDays.max()
        let statsEndDate = latestCompletedDay.map { max(today, $0) } ?? today

        switch habit.schedule {
        case .weeklyQuota(let quota):
            return quotaStats(for: habit, entries: entries, referenceDate: today, quota: quota, component: .weekOfYear)
        case .monthlyQuota(let quota):
            return quotaStats(for: habit, entries: entries, referenceDate: today, quota: quota, component: .month)
        case .daily, .weekdays, .interval:
            let dueDates = dueDates(for: habit, through: statsEndDate, lookbackDays: lookbackDays)
            let weekStart = habitCalendar.startOfWeek(containing: today)
            let streaks = dailyLikeStreaks(
                dueDates: dueDates,
                completedDays: completedDays,
                graceReferenceDate: today
            )
            let thisWeek: [Date]
            if case .weekdays = habit.schedule {
                thisWeek = selectedDatesForVisibleWeek(habit: habit, weekStart: weekStart)
            } else {
                thisWeek = dueDates.filter { habitCalendar.startOfWeek(containing: $0) == weekStart }
            }
            let completedThisWeek = thisWeek.filter { completedDays.contains($0) }.count
            let completionRate = thisWeek.isEmpty ? 0 : Double(completedThisWeek) / Double(thisWeek.count)

            return HabitStats(
                currentStreak: streaks.current,
                bestStreak: streaks.best,
                completionRate: completionRate,
                completedThisWeek: completedThisWeek,
                dueThisWeek: thisWeek.count
            )
        }
    }

    public func dueDates(for habit: Habit, through referenceDate: Date, lookbackDays: Int) -> [Date] {
        let end = habitCalendar.startOfDay(for: referenceDate)
        let start = habitCalendar.date(byAddingDays: -lookbackDays, to: end)

        return (0...lookbackDays)
            .map { habitCalendar.date(byAddingDays: $0, to: start) }
            .filter { isDueForStats(habit: habit, on: $0) && $0 <= end }
    }

    private func selectedDatesForVisibleWeek(habit: Habit, weekStart: Date) -> [Date] {
        (0..<7)
            .map { habitCalendar.date(byAddingDays: $0, to: weekStart) }
            .filter { isSelectedTrackingDay(habit: habit, on: $0) }
    }

    private func isSelectedTrackingDay(habit: Habit, on date: Date) -> Bool {
        guard !habit.isArchived else { return false }

        switch habit.schedule {
        case .daily, .weeklyQuota, .monthlyQuota:
            return true
        case .weekdays(let weekdays):
            return weekdays.contains(habitCalendar.weekday(for: date))
        case .interval(let everyDays, let startDate):
            guard everyDays > 0 else { return false }
            let distance = habitCalendar.daysBetween(startDate, date)
            return distance >= 0 && distance % everyDays == 0
        }
    }

    private func isDueForStats(habit: Habit, on date: Date) -> Bool {
        guard !habit.isArchived else { return false }

        switch habit.schedule {
        case .weekdays:
            return isSelectedTrackingDay(habit: habit, on: date)
        case .daily, .weeklyQuota, .monthlyQuota, .interval:
            return isDue(habit: habit, on: date)
        }
    }

    private func dailyLikeStreaks(
        dueDates: [Date],
        completedDays: Set<Date>,
        graceReferenceDate: Date
    ) -> (current: Int, best: Int) {
        var best = 0
        var running = 0
        var completedRuns: [(start: Date, end: Date, length: Int)] = []
        var runStart: Date?
        var lastCompletedDate: Date?

        for date in dueDates {
            if completedDays.contains(date) {
                if runStart == nil {
                    runStart = date
                }
                lastCompletedDate = date
                running += 1
            } else {
                if let runStart, let lastCompletedDate, running > 0 {
                    completedRuns.append((start: runStart, end: lastCompletedDate, length: running))
                }
                runStart = nil
                lastCompletedDate = nil
                running = 0
            }
        }

        if let runStart, let lastCompletedDate, running > 0 {
            completedRuns.append((start: runStart, end: lastCompletedDate, length: running))
        }

        var current = 0
        for date in dueDates.reversed() {
            if completedDays.contains(date) {
                current += 1
                continue
            }

            let distance = habitCalendar.daysBetween(date, graceReferenceDate)
            if distance == 0 || distance == 1 {
                continue
            }

            break
        }

        best = completedRuns.map(\.length).max() ?? 0

        return (current, best)
    }

    private func quotaStats(
        for habit: Habit,
        entries: [HabitEntry],
        referenceDate: Date,
        quota: Int,
        component: Calendar.Component
    ) -> HabitStats {
        let periods = periodStarts(through: referenceDate, component: component, lookbackCount: 24)
        let habitEntries = entriesForHabit(habit.id, entries: entries)
        let completionsByPeriod = Dictionary(grouping: habitEntries) { entry in
            component == .weekOfYear
                ? habitCalendar.startOfWeek(containing: entry.targetDate)
                : habitCalendar.startOfMonth(containing: entry.targetDate)
        }
        let satisfied = Set(periods.filter { (completionsByPeriod[$0]?.count ?? 0) >= quota })
        let currentPeriod = component == .weekOfYear
            ? habitCalendar.startOfWeek(containing: referenceDate)
            : habitCalendar.startOfMonth(containing: referenceDate)

        var best = 0
        var running = 0
        for period in periods {
            if satisfied.contains(period) {
                running += 1
                best = max(best, running)
            } else {
                running = 0
            }
        }

        var current = 0
        for period in periods.reversed() {
            if satisfied.contains(period) {
                current += 1
            } else if period == currentPeriod {
                continue
            } else {
                break
            }
        }

        let currentCompletions = completionsByPeriod[currentPeriod]?.count ?? 0
        let completionRate = periods.isEmpty ? 0 : Double(satisfied.count) / Double(periods.count)

        return HabitStats(
            currentStreak: current,
            bestStreak: best,
            completionRate: completionRate,
            completedThisWeek: currentCompletions,
            dueThisWeek: quota
        )
    }

    private func periodStarts(through referenceDate: Date, component: Calendar.Component, lookbackCount: Int) -> [Date] {
        let current = component == .weekOfYear
            ? habitCalendar.startOfWeek(containing: referenceDate)
            : habitCalendar.startOfMonth(containing: referenceDate)

        return (0..<lookbackCount).compactMap { offset in
            habitCalendar.calendar.date(byAdding: component, value: offset - lookbackCount + 1, to: current)
        }
    }

    private func entry(for habitID: UUID, targetDate: Date, entries: [HabitEntry]) -> HabitEntry? {
        entriesForHabit(habitID, entries: entries)
            .first { habitCalendar.startOfDay(for: $0.targetDate) == targetDate }
    }

    private func entriesForHabit(_ habitID: UUID, entries: [HabitEntry]) -> [HabitEntry] {
        entries.filter { $0.habitID == habitID }
    }
}
