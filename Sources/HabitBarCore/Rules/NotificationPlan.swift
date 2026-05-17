import Foundation

public struct NotificationPlan: Equatable, Sendable {
    public var habitID: UUID
    public var title: String
    public var body: String
    public var hour: Int
    public var minute: Int
    public var weekday: Weekday?
    public var targetDate: Date?
    public var leadTime: ReminderLeadTime

    public init(
        habitID: UUID,
        title: String,
        body: String,
        hour: Int,
        minute: Int,
        weekday: Weekday? = nil,
        targetDate: Date? = nil,
        leadTime: ReminderLeadTime = .rightOnTime
    ) {
        self.habitID = habitID
        self.title = title
        self.body = body
        self.hour = hour
        self.minute = minute
        self.weekday = weekday
        self.targetDate = targetDate
        self.leadTime = leadTime
    }
}

public struct NotificationPlanner: Sendable {
    private let engine: HabitRuleEngine

    public init(engine: HabitRuleEngine = HabitRuleEngine()) {
        self.engine = engine
    }

    public func plans(habits: [Habit], entries: [HabitEntry], referenceDate: Date) -> [NotificationPlan] {
        var planned: [NotificationPlan] = []

        for habit in habits {
            if case .weekdays = habit.schedule {
                planned.append(contentsOf: weekdayPlans(for: habit, referenceDate: referenceDate))
                continue
            }

            if case .interval = habit.schedule {
                planned.append(contentsOf: intervalPlans(for: habit, entries: entries, referenceDate: referenceDate))
                continue
            }

            if shouldSchedule(habit: habit, entries: entries, referenceDate: referenceDate) {
                planned.append(contentsOf: plans(for: habit, referenceDate: referenceDate))
            }
        }

        return planned
    }

    public func shouldSchedule(habit: Habit, entries: [HabitEntry], referenceDate: Date) -> Bool {
        guard !habit.isArchived, habit.reminder.isEnabled else {
            return false
        }

        if case .interval = habit.schedule {
            return nextDueIntervalDate(for: habit, entries: entries, referenceDate: referenceDate) != nil
        }

        if case .weekdays = habit.schedule {
            return !weekdayPlans(for: habit, referenceDate: referenceDate).isEmpty
        }

        let stats = engine.stats(for: habit, entries: entries, referenceDate: referenceDate)

        switch habit.schedule {
        case .weeklyQuota, .monthlyQuota:
            return stats.completedThisWeek < stats.dueThisWeek
        default:
            switch engine.dayState(
                habit: habit,
                entries: entries,
                date: referenceDate,
                referenceDate: referenceDate
            ) {
            case .today, .graceEligible, .missed:
                return true
            case .completed, .future, .offSchedule:
                return false
            }
        }
    }

    private func plans(for habit: Habit, referenceDate: Date) -> [NotificationPlan] {
        let body = habit.reminder.message.isEmpty ? "Time for \(habit.name)" : habit.reminder.message
        return reminderLeadTimes(for: habit).map { leadTime in
            let time = adjustedTime(for: habit, leadTime: leadTime)
            return NotificationPlan(
                habitID: habit.id,
                title: habit.name,
                body: body,
                hour: time.hour,
                minute: time.minute,
                leadTime: leadTime
            )
        }
    }

    private func weekdayPlans(for habit: Habit, referenceDate: Date) -> [NotificationPlan] {
        guard !habit.isArchived, habit.reminder.isEnabled else { return [] }
        guard case .weekdays(let weekdays) = habit.schedule else { return [] }

        let body = habit.reminder.message.isEmpty ? "Time for \(habit.name)" : habit.reminder.message
        return weekdays.sorted { $0.rawValue < $1.rawValue }.flatMap { weekday in
            reminderLeadTimes(for: habit).map { leadTime in
                let time = nextWeekdayReminderTime(for: habit, weekday: weekday, leadTime: leadTime, referenceDate: referenceDate)
                return NotificationPlan(
                    habitID: habit.id,
                    title: habit.name,
                    body: body,
                    hour: time.hour,
                    minute: time.minute,
                    targetDate: time.targetDate,
                    leadTime: leadTime
                )
            }
        }
    }

    private func intervalPlans(for habit: Habit, entries: [HabitEntry], referenceDate: Date) -> [NotificationPlan] {
        guard !habit.isArchived, habit.reminder.isEnabled else { return [] }
        guard let nextDueDate = nextDueIntervalDate(for: habit, entries: entries, referenceDate: referenceDate) else {
            return []
        }

        let body = habit.reminder.message.isEmpty ? "Time for \(habit.name)" : habit.reminder.message
        return reminderLeadTimes(for: habit).map { leadTime in
            let time = adjustedTime(for: habit, targetDate: nextDueDate, leadTime: leadTime)
            return NotificationPlan(
                habitID: habit.id,
                title: habit.name,
                body: body,
                hour: time.hour,
                minute: time.minute,
                targetDate: time.targetDate,
                leadTime: leadTime
            )
        }
    }

    private func nextDueIntervalDate(for habit: Habit, entries: [HabitEntry], referenceDate: Date) -> Date? {
        guard case .interval = habit.schedule else { return nil }

        let calendar = engine.habitCalendar
        let start = calendar.startOfDay(for: referenceDate)

        return (0...366)
            .map { calendar.date(byAddingDays: $0, to: start) }
            .first { date in
                engine.isDue(habit: habit, on: date) && !isCompleted(habit: habit, on: date, entries: entries)
            }
    }

    private func isCompleted(habit: Habit, on date: Date, entries: [HabitEntry]) -> Bool {
        let calendar = engine.habitCalendar
        let day = calendar.startOfDay(for: date)

        return entries.contains {
            $0.habitID == habit.id && calendar.startOfDay(for: $0.targetDate) == day
        }
    }

    private func reminderLeadTimes(for habit: Habit) -> [ReminderLeadTime] {
        ReminderLeadTime.allCases.filter { habit.reminder.leadTimes.contains($0) }
    }

    private func adjustedTime(
        for habit: Habit,
        weekday: Weekday? = nil,
        targetDate: Date? = nil,
        leadTime: ReminderLeadTime
    ) -> (hour: Int, minute: Int, weekday: Weekday?, targetDate: Date?) {
        var components = DateComponents()
        components.hour = habit.reminder.hour
        components.minute = habit.reminder.minute

        let calendar = engine.habitCalendar.calendar
        let baseDate = targetDate ?? date(for: weekday)
        let reminderDate = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: baseDate))
            .flatMap { calendar.date(byAdding: components, to: $0) }
            .flatMap { calendar.date(byAdding: .minute, value: -leadTime.rawValue, to: $0) }
            ?? baseDate

        return (
            calendar.component(.hour, from: reminderDate),
            calendar.component(.minute, from: reminderDate),
            weekday == nil ? nil : engine.habitCalendar.weekday(for: reminderDate),
            targetDate == nil ? nil : engine.habitCalendar.startOfDay(for: reminderDate)
        )
    }

    private func nextWeekdayReminderTime(
        for habit: Habit,
        weekday: Weekday,
        leadTime: ReminderLeadTime,
        referenceDate: Date
    ) -> (hour: Int, minute: Int, targetDate: Date) {
        let calendar = engine.habitCalendar.calendar
        let referenceDay = engine.habitCalendar.startOfDay(for: referenceDate)
        let daysUntilWeekday = (weekday.rawValue - calendar.component(.weekday, from: referenceDay) + 7) % 7
        let dueDay = engine.habitCalendar.date(byAddingDays: daysUntilWeekday, to: referenceDay)
        var scheduledDate = reminderDate(for: habit, dueDate: dueDay, leadTime: leadTime)

        if scheduledDate <= referenceDate {
            let nextDueDay = engine.habitCalendar.date(byAddingDays: 7, to: dueDay)
            scheduledDate = reminderDate(for: habit, dueDate: nextDueDay, leadTime: leadTime)
        }

        return (
            calendar.component(.hour, from: scheduledDate),
            calendar.component(.minute, from: scheduledDate),
            engine.habitCalendar.startOfDay(for: scheduledDate)
        )
    }

    private func reminderDate(for habit: Habit, dueDate: Date, leadTime: ReminderLeadTime) -> Date {
        var components = DateComponents()
        components.hour = habit.reminder.hour
        components.minute = habit.reminder.minute

        let calendar = engine.habitCalendar.calendar
        return calendar.date(from: calendar.dateComponents([.year, .month, .day], from: dueDate))
            .flatMap { calendar.date(byAdding: components, to: $0) }
            .flatMap { calendar.date(byAdding: .minute, value: -leadTime.rawValue, to: $0) }
            ?? dueDate
    }

    private func date(for weekday: Weekday?) -> Date {
        let calendar = engine.habitCalendar.calendar
        let weekStart = engine.habitCalendar.startOfWeek(containing: Date(timeIntervalSince1970: 0))
        let daysFromMonday = weekday?.mondayFirstSortIndex ?? 0
        return calendar.date(byAdding: .day, value: daysFromMonday, to: weekStart) ?? weekStart
    }
}
