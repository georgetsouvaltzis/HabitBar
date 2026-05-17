import Foundation
import HabitBarCore
import Observation

@Observable
final class HabitBarModel {
    var snapshot: HabitSnapshot
    var selectedHabitID: UUID?
    var editingHabit: Habit?
    var isShowingEditor = false
    var isShowingArchive = false
    var errorMessage: String?

    private let store: HabitStoreProtocol
    private let notificationScheduler: NotificationScheduling
    private let engine = HabitRuleEngine()

    init(
        store: HabitStoreProtocol = JSONHabitStore(),
        notificationScheduler: NotificationScheduling = NotificationSchedulerFactory.makeDefault()
    ) {
        self.store = store
        self.notificationScheduler = notificationScheduler
        let loaded = (try? store.load()) ?? HabitSnapshot()
        self.snapshot = Self.normalizedSnapshot(loaded)
        self.selectedHabitID = snapshot.habits.first(where: { !$0.isArchived })?.id
        synchronizeNotifications()
    }

    convenience init(uiTesting: Bool) {
        if uiTesting {
            self.init(
                store: InMemoryHabitStore(snapshot: .sample),
                notificationScheduler: DisabledNotificationScheduler()
            )
        } else {
            self.init()
        }
    }

    var activeHabits: [Habit] {
        snapshot.habits.filter { !$0.isArchived }
    }

    var archivedHabits: [Habit] {
        snapshot.habits.filter(\.isArchived)
    }

    func stats(for habit: Habit, referenceDate: Date = Date()) -> HabitStats {
        engine.stats(for: habit, entries: snapshot.entries, referenceDate: referenceDate)
    }

    func dayState(for habit: Habit, date: Date, referenceDate: Date = Date()) -> HabitDayState {
        engine.dayState(habit: habit, entries: snapshot.entries, date: date, referenceDate: referenceDate)
    }

    func isTrackingDay(for habit: Habit, date: Date) -> Bool {
        guard !habit.isArchived else { return false }

        switch habit.schedule {
        case .weekdays(let weekdays):
            let weekday = Calendar.current.component(.weekday, from: date)
            return weekdays.contains(Weekday(rawValue: weekday) ?? .monday)
        case .daily, .weeklyQuota, .monthlyQuota:
            return true
        case .interval(let everyDays, let startDate):
            guard everyDays > 0 else { return false }
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: startDate)
            let day = calendar.startOfDay(for: date)
            let distance = calendar.dateComponents([.day], from: start, to: day).day ?? 0
            return distance >= 0 && distance % everyDays == 0
        }
    }

    func toggleToday(for habit: Habit) {
        switch dayState(for: habit, date: Date()) {
        case .completed, .today:
            break
        case .graceEligible, .missed, .future, .offSchedule:
            return
        }

        toggle(habit: habit, targetDate: Date(), completedAt: Date())
    }

    func toggle(habit: Habit, targetDate: Date, completedAt: Date = Date()) {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: targetDate)
        var updatedSnapshot = snapshot

        if let index = updatedSnapshot.entries.firstIndex(where: {
            $0.habitID == habit.id && calendar.isDate($0.targetDate, inSameDayAs: targetDay)
        }) {
            updatedSnapshot.entries.remove(at: index)
        } else {
            updatedSnapshot.entries.append(
                HabitEntry(
                    habitID: habit.id,
                    targetDate: targetDay,
                    completedAt: completedAt,
                    source: .normal
                )
            )
        }

        snapshot = updatedSnapshot
        save()
    }

    func addHabit() {
        editingHabit = Habit(
            name: "",
            symbolName: "figure.walk",
            color: .green,
            schedule: .weekdays(Self.defaultWeekdays),
            reminder: HabitReminder(isEnabled: false)
        )
        isShowingEditor = true
    }

    func edit(_ habit: Habit) {
        editingHabit = habit
        isShowingEditor = true
    }

    func saveEditedHabit(_ habit: Habit) {
        let trimmed = habit.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Habit name is required."
            return
        }

        var updated = habit
        updated.name = trimmed
        if case .weekdays = updated.schedule {
        } else {
            updated.schedule = .weekdays(Self.defaultWeekdays)
        }

        if let index = snapshot.habits.firstIndex(where: { $0.id == updated.id }) {
            snapshot.habits[index] = updated
        } else {
            snapshot.habits.append(updated)
        }

        selectedHabitID = updated.id
        editingHabit = nil
        isShowingEditor = false
        save()
    }

    func archive(_ habit: Habit) {
        updateHabit(habit.id) {
            $0.isArchived = true
            $0.archivedAt = Date()
        }
        selectedHabitID = activeHabits.first?.id
    }

    func restore(_ habit: Habit) {
        updateHabit(habit.id) {
            $0.isArchived = false
            $0.archivedAt = nil
        }
        selectedHabitID = habit.id
        isShowingArchive = false
    }

    func delete(_ habit: Habit) {
        snapshot.habits.removeAll { $0.id == habit.id }
        snapshot.entries.removeAll { $0.habitID == habit.id }
        selectedHabitID = activeHabits.first?.id
        save()
    }

    func setTheme(_ theme: AppTheme) {
        snapshot.theme = theme
        save()
    }

    func showHabitFromNotification(_ id: UUID) {
        guard snapshot.habits.contains(where: { $0.id == id && !$0.isArchived }) else { return }
        editingHabit = nil
        isShowingEditor = false
        isShowingArchive = false
        selectedHabitID = id
    }

    private func updateHabit(_ id: UUID, mutation: (inout Habit) -> Void) {
        guard let index = snapshot.habits.firstIndex(where: { $0.id == id }) else { return }
        mutation(&snapshot.habits[index])
        save()
    }

    private func save() {
        do {
            try store.save(snapshot)
            errorMessage = nil
            synchronizeNotifications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func synchronizeNotifications() {
        notificationScheduler.synchronize(habits: snapshot.habits, entries: snapshot.entries, referenceDate: Date())
    }

    private static let defaultWeekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]

    private static func normalizedSnapshot(_ snapshot: HabitSnapshot) -> HabitSnapshot {
        var normalized = snapshot
        normalized.habits = normalized.habits.map { habit in
            var updated = habit
            if case .weekdays = updated.schedule {
                return updated
            }
            updated.schedule = .weekdays(defaultWeekdays)
            return updated
        }
        return normalized
    }
}

private struct InMemoryHabitStore: HabitStoreProtocol {
    var snapshot: HabitSnapshot

    var hasSavedSnapshot: Bool {
        true
    }

    func load() throws -> HabitSnapshot {
        snapshot
    }

    func save(_ snapshot: HabitSnapshot) throws {}
}
