import Foundation
import HabitBarCore

extension HabitSnapshot {
    static var sample: HabitSnapshot {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) ?? today
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today) ?? today
        let sampleStart = calendar.date(byAdding: .day, value: -90, to: today) ?? today
        let weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]

        let walk = Habit(
            name: "Morning Walk",
            symbolName: "figure.walk",
            color: .green,
            schedule: .weekdays(weekdays),
            reminder: HabitReminder(isEnabled: true, hour: 7, minute: 30, message: "Time for your walk"),
            createdAt: sampleStart
        )
        let read = Habit(name: "Read 20 min", symbolName: "book.fill", color: .blue, schedule: .weekdays(weekdays), createdAt: sampleStart)
        let hydrate = Habit(name: "Hydrate", symbolName: "drop.fill", color: .cyan, schedule: .weekdays(weekdays), createdAt: sampleStart)
        let meditate = Habit(
            name: "Meditate",
            symbolName: "leaf.fill",
            color: .violet,
            schedule: .weekdays([.monday, .wednesday, .friday]),
            createdAt: sampleStart
        )
        let sugar = Habit(name: "No Sugar", symbolName: "cube.box.fill", color: .orange, schedule: .weekdays(weekdays), createdAt: sampleStart)

        return HabitSnapshot(
            habits: [walk, read, hydrate, meditate, sugar],
            entries: [
                HabitEntry(habitID: walk.id, targetDate: today, source: .normal),
                HabitEntry(habitID: walk.id, targetDate: twoDaysAgo, source: .normal),
                HabitEntry(habitID: walk.id, targetDate: threeDaysAgo, source: .normal),
                HabitEntry(habitID: read.id, targetDate: yesterday, source: .normal),
                HabitEntry(habitID: hydrate.id, targetDate: today, source: .normal),
                HabitEntry(habitID: sugar.id, targetDate: today, source: .normal)
            ]
        )
    }
}
