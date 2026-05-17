import Foundation

public struct JSONHabitStore: HabitStoreProtocol {
    public let url: URL

    public init(url: URL = JSONHabitStore.defaultURL()) {
        self.url = url
    }

    public var hasSavedSnapshot: Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    public func load() throws -> HabitSnapshot {
        guard hasSavedSnapshot else {
            return HabitSnapshot()
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(HabitSnapshot.self, from: data)
    }

    public func save(_ snapshot: HabitSnapshot) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        try data.write(to: url, options: [.atomic])
    }

    public static func defaultURL() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return support.appendingPathComponent("HabitBar/Habits.json")
    }
}
