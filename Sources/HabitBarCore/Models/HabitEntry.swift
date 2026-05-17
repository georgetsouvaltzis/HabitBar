import Foundation

public enum CompletionSource: String, Codable, Hashable, Sendable {
    case normal
    case grace
    case manualBackfill
}

public struct HabitEntry: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var habitID: UUID
    public var targetDate: Date
    public var completedAt: Date
    public var source: CompletionSource
    public var note: String?

    public init(
        id: UUID = UUID(),
        habitID: UUID,
        targetDate: Date,
        completedAt: Date = Date(),
        source: CompletionSource,
        note: String? = nil
    ) {
        self.id = id
        self.habitID = habitID
        self.targetDate = targetDate
        self.completedAt = completedAt
        self.source = source
        self.note = note
    }
}

