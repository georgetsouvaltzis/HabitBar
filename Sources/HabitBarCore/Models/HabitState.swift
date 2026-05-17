public enum HabitDayState: Equatable, Sendable {
    case completed(CompletionSource)
    case today
    case graceEligible
    case missed
    case future
    case offSchedule
}

public struct HabitStats: Equatable, Sendable {
    public var currentStreak: Int
    public var bestStreak: Int
    public var completionRate: Double
    public var completedThisWeek: Int
    public var dueThisWeek: Int

    public init(
        currentStreak: Int,
        bestStreak: Int,
        completionRate: Double,
        completedThisWeek: Int,
        dueThisWeek: Int
    ) {
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.completionRate = completionRate
        self.completedThisWeek = completedThisWeek
        self.dueThisWeek = dueThisWeek
    }
}

