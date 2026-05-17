import Foundation

public struct Habit: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var symbolName: String
    public var color: HabitColor
    public var schedule: HabitSchedule
    public var reminder: HabitReminder
    public var allowsGrace: Bool
    public var isArchived: Bool
    public var createdAt: Date
    public var archivedAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case symbolName
        case color
        case schedule
        case reminder
        case allowsGrace
        case isArchived
        case createdAt
        case archivedAt
    }

    public init(
        id: UUID = UUID(),
        name: String,
        symbolName: String,
        color: HabitColor,
        schedule: HabitSchedule,
        reminder: HabitReminder = HabitReminder(),
        allowsGrace: Bool = true,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.color = color
        self.schedule = schedule
        self.reminder = reminder
        self.allowsGrace = allowsGrace
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.archivedAt = archivedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        symbolName = try container.decode(String.self, forKey: .symbolName)
        color = try container.decode(HabitColor.self, forKey: .color)
        schedule = try container.decode(HabitSchedule.self, forKey: .schedule)
        reminder = try container.decode(HabitReminder.self, forKey: .reminder)
        allowsGrace = try container.decodeIfPresent(Bool.self, forKey: .allowsGrace) ?? true
        isArchived = try container.decode(Bool.self, forKey: .isArchived)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        archivedAt = try container.decodeIfPresent(Date.self, forKey: .archivedAt)
    }
}

public struct HabitReminder: Codable, Hashable, Sendable {
    public var isEnabled: Bool
    public var hour: Int
    public var minute: Int
    public var message: String
    public var leadTimes: Set<ReminderLeadTime>

    private enum CodingKeys: String, CodingKey {
        case isEnabled
        case hour
        case minute
        case message
        case leadTimes
    }

    public init(
        isEnabled: Bool = false,
        hour: Int = 7,
        minute: Int = 30,
        message: String = "",
        leadTimes: Set<ReminderLeadTime> = [.rightOnTime]
    ) {
        self.isEnabled = isEnabled
        self.hour = hour
        self.minute = minute
        self.message = message
        self.leadTimes = leadTimes.isEmpty ? [.rightOnTime] : leadTimes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        hour = try container.decode(Int.self, forKey: .hour)
        minute = try container.decode(Int.self, forKey: .minute)
        message = try container.decode(String.self, forKey: .message)
        let decodedLeadTimes = try container.decodeIfPresent(Set<ReminderLeadTime>.self, forKey: .leadTimes)
        if let decodedLeadTimes, !decodedLeadTimes.isEmpty {
            leadTimes = decodedLeadTimes
        } else {
            leadTimes = [.rightOnTime]
        }
    }

    public var timeLabel: String {
        let suffix = hour >= 12 ? "PM" : "AM"
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        return "\(displayHour):\(String(format: "%02d", minute)) \(suffix)"
    }
}

public enum ReminderLeadTime: Int, Codable, CaseIterable, Hashable, Sendable {
    case oneHourBefore = 60
    case rightOnTime = 0
    case fifteenMinutesBefore = 15
    case thirtyMinutesBefore = 30

    public var title: String {
        switch self {
        case .oneHourBefore:
            return "1 hour before"
        case .rightOnTime:
            return "Right on time"
        case .fifteenMinutesBefore:
            return "15 mins before"
        case .thirtyMinutesBefore:
            return "30 mins before"
        }
    }
}
