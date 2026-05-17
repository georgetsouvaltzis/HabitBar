public struct HabitSnapshot: Codable, Equatable, Sendable {
    public var habits: [Habit]
    public var entries: [HabitEntry]
    public var theme: AppTheme

    private enum CodingKeys: String, CodingKey {
        case habits
        case entries
        case theme
    }

    public init(habits: [Habit] = [], entries: [HabitEntry] = [], theme: AppTheme = .system) {
        self.habits = habits
        self.entries = entries
        self.theme = theme
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        habits = try container.decode([Habit].self, forKey: .habits)
        entries = try container.decode([HabitEntry].self, forKey: .entries)
        theme = try container.decodeIfPresent(AppTheme.self, forKey: .theme) ?? .system
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(habits, forKey: .habits)
        try container.encode(entries, forKey: .entries)
        try container.encode(theme, forKey: .theme)
    }
}

public protocol HabitStoreProtocol: Sendable {
    var hasSavedSnapshot: Bool { get }

    func load() throws -> HabitSnapshot
    func save(_ snapshot: HabitSnapshot) throws
}
