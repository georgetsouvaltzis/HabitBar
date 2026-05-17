import XCTest
@testable import HabitBarCore

final class JSONHabitStoreTests: XCTestCase {
    func testSaveAndLoadRoundTripsSnapshot() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("Habits.json")
        let store = JSONHabitStore(url: url)
        let habit = Habit(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "Hydrate",
            symbolName: "drop.fill",
            color: .cyan,
            schedule: .daily,
            reminder: HabitReminder(isEnabled: true, hour: 9, minute: 15, message: "Drink water"),
            createdAt: Date(timeIntervalSince1970: 0)
        )
        let snapshot = HabitSnapshot(
            habits: [habit],
            entries: [
                HabitEntry(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
                    habitID: habit.id,
                    targetDate: Date(timeIntervalSince1970: 0),
                    completedAt: Date(timeIntervalSince1970: 0),
                    source: .manualBackfill
                )
            ],
            theme: .dark
        )

        try store.save(snapshot)
        let loaded = try store.load()

        XCTAssertEqual(loaded, snapshot)
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    func testMissingGraceFieldDefaultsToEnabled() throws {
        let json = """
        {
          "id": "00000000-0000-0000-0000-000000000003",
          "name": "Hydrate",
          "symbolName": "drop.fill",
          "color": {
            "red": 0.1,
            "green": 0.5,
            "blue": 0.9
          },
          "schedule": {
            "type": "daily"
          },
          "reminder": {
            "isEnabled": false,
            "hour": 7,
            "minute": 30,
            "message": ""
          },
          "isArchived": false,
          "createdAt": "2026-05-12T00:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let habit = try decoder.decode(Habit.self, from: Data(json.utf8))

        XCTAssertTrue(habit.allowsGrace)
        XCTAssertEqual(habit.reminder.leadTimes, [.rightOnTime])
    }

    func testMissingThemeDefaultsToSystem() throws {
        let json = """
        {
          "habits": [],
          "entries": []
        }
        """
        let snapshot = try JSONDecoder().decode(HabitSnapshot.self, from: Data(json.utf8))

        XCTAssertEqual(snapshot.theme, .system)
        XCTAssertEqual(snapshot.habits, [])
        XCTAssertEqual(snapshot.entries, [])
    }

    func testMissingStoreLoadsEmptySnapshot() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("Missing.json")
        let store = JSONHabitStore(url: url)

        XCTAssertEqual(try store.load(), HabitSnapshot())
        XCTAssertFalse(store.hasSavedSnapshot)
    }
}
