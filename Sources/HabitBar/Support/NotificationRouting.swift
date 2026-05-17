import Foundation

enum NotificationRouting {
    static let habitIDKey = "habitID"

    @MainActor private static var handler: ((UUID) -> Void)?
    @MainActor private static var pendingHabitID: UUID?

    static func installHandler(_ handler: @escaping @MainActor (UUID) -> Void) {
        Task { @MainActor in
            self.handler = handler

            if let pendingHabitID {
                self.pendingHabitID = nil
                handler(pendingHabitID)
            }
        }
    }

    static func route(habitIDString: String) {
        guard let habitID = UUID(uuidString: habitIDString) else { return }

        Task { @MainActor in
            if let handler {
                handler(habitID)
            } else {
                pendingHabitID = habitID
            }
        }
    }
}
