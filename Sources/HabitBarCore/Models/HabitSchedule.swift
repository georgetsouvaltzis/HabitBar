import Foundation

public enum HabitSchedule: Codable, Hashable, Sendable {
    case daily
    case weekdays(Set<Weekday>)
    case weeklyQuota(Int)
    case monthlyQuota(Int)
    case interval(everyDays: Int, startDate: Date)

    private enum CodingKeys: String, CodingKey {
        case type
        case weekdays
        case quota
        case everyDays
        case startDate
    }

    private enum Kind: String, Codable {
        case daily
        case weekdays
        case weeklyQuota
        case monthlyQuota
        case interval
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(Kind.self, forKey: .type)

        switch type {
        case .daily:
            self = .daily
        case .weekdays:
            self = .weekdays(try container.decode(Set<Weekday>.self, forKey: .weekdays))
        case .weeklyQuota:
            self = .weeklyQuota(try container.decode(Int.self, forKey: .quota))
        case .monthlyQuota:
            self = .monthlyQuota(try container.decode(Int.self, forKey: .quota))
        case .interval:
            self = .interval(
                everyDays: try container.decode(Int.self, forKey: .everyDays),
                startDate: try container.decode(Date.self, forKey: .startDate)
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .daily:
            try container.encode(Kind.daily, forKey: .type)
        case .weekdays(let weekdays):
            try container.encode(Kind.weekdays, forKey: .type)
            try container.encode(weekdays, forKey: .weekdays)
        case .weeklyQuota(let quota):
            try container.encode(Kind.weeklyQuota, forKey: .type)
            try container.encode(quota, forKey: .quota)
        case .monthlyQuota(let quota):
            try container.encode(Kind.monthlyQuota, forKey: .type)
            try container.encode(quota, forKey: .quota)
        case .interval(let everyDays, let startDate):
            try container.encode(Kind.interval, forKey: .type)
            try container.encode(everyDays, forKey: .everyDays)
            try container.encode(startDate, forKey: .startDate)
        }
    }
}

public extension HabitSchedule {
    var title: String {
        switch self {
        case .daily:
            "Daily"
        case .weekdays(let days):
            days.sorted { $0.mondayFirstSortIndex < $1.mondayFirstSortIndex }.map(\.shortTitle).joined(separator: ", ")
        case .weeklyQuota(let count):
            "\(count)x weekly"
        case .monthlyQuota(let count):
            "\(count)x monthly"
        case .interval(let days, _):
            "Every \(days) days"
        }
    }
}
