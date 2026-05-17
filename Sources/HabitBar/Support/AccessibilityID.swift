enum AccessibilityID {
    static let menuRoot = "habitbar.menu.root"
    static let addHabit = "habitbar.addHabit"
    static let archive = "habitbar.archive"
    static let habitNameField = "habitbar.edit.name"
    static let saveHabit = "habitbar.edit.save"

    static func habitRow(_ id: String) -> String {
        "habitbar.habit.row.\(id)"
    }

    static func completeButton(_ id: String) -> String {
        "habitbar.habit.complete.\(id)"
    }

    static func gridCell(habitID: String, day: String) -> String {
        "habitbar.grid.\(habitID).\(day)"
    }
}
