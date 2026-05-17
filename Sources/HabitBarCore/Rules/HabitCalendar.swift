import Foundation

public struct HabitCalendar: Sendable {
    public var calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    public func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    public func date(byAddingDays days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: startOfDay(for: date)) ?? date
    }

    public func daysBetween(_ start: Date, _ end: Date) -> Int {
        calendar.dateComponents([.day], from: startOfDay(for: start), to: startOfDay(for: end)).day ?? 0
    }

    public func weekday(for date: Date) -> Weekday {
        Weekday(rawValue: calendar.component(.weekday, from: date)) ?? .monday
    }

    public func startOfWeek(containing date: Date) -> Date {
        let day = startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: day)
        let daysFromMonday = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: day) ?? day
    }

    public func startOfMonth(containing date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? startOfDay(for: date)
    }
}
