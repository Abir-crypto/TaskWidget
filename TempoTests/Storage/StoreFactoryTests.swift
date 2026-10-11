import Core
import Foundation
import SwiftData
import Testing

@testable import Tempo

struct StoreFactoryTests {
    @Test func sharedStoreLivesInTheAppGroup() throws {
        let url = try StoreFactory.storeURL()
        let group = try #require(
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: StoreFactory.appGroup))
        #expect(url.lastPathComponent == "Tempo.store")
        #expect(url.deletingLastPathComponent().standardizedFileURL == group.standardizedFileURL)
    }

    /// A store written by version 1 opens under version 2 with its data, and its settings row gets the default
    /// theme color (SPEC T-33, ios.md §6).
    @Test func versionOneStoreMigratesWithItsData() throws {
        let url = try StoreFactory.storeURL(fileName: "Tempo-v1-\(UUID().uuidString).store")
        defer { Self.removeStore(at: url) }
        let taskID = UUID()
        do {
            let schema = Schema(versionedSchema: SchemaV1.self)
            let old = try ModelContainer(
                for: schema, configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none))
            let context = ModelContext(old)
            let task = SchemaV1.TaskRecord()
            task.id = taskID
            task.title = "Read"
            context.insert(task)
            let settings = SchemaV1.SettingsRecord()
            settings.id = SwiftDataTaskStore.settingsID
            settings.hideLockScreenTitles = true
            context.insert(settings)
            try context.save()
        }

        let store = SwiftDataTaskStore(container: try StoreFactory.make(url: url), clock: TestEnvironment.clock())
        #expect(try store.task(id: taskID)?.title == "Read")
        let settings = try #require(try store.settings())
        #expect(settings.hideLockScreenTitles)
        #expect(settings.tintColor == .preset(.blue))
    }

    /// The app and the widget extension each open their own container on the App Group file. Two containers on
    /// one file, each using fresh contexts, must see each other's writes (SPEC T-03, ios.md §6).
    @Test func writesFromOneContainerAreReadByAnother() throws {
        let url = try StoreFactory.storeURL(fileName: "Tempo-test-\(UUID().uuidString).store")
        defer { Self.removeStore(at: url) }
        let clock = TestEnvironment.clock()
        let app = SwiftDataTaskStore(container: try StoreFactory.make(url: url), clock: clock)
        let widget = SwiftDataTaskStore(container: try StoreFactory.make(url: url), clock: clock)

        let task = try app.save(
            TaskValue(title: "Read", type: .duration, startDay: TestEnvironment.today, createdAt: clock.now))
        try app.save(SettingsValue.defaults)
        #expect(try widget.task(id: task.id)?.title == "Read")
        #expect(try widget.settings() != nil)

        // And the other way: a widget button writes, and the app reads it.
        clock.advance(by: 60)
        try widget.save(
            TimeEntryValue(
                taskID: task.id, day: TestEnvironment.today, seconds: 600, source: .timer, createdAt: clock.now))
        #expect(try app.timeEntries(taskID: task.id).map(\.seconds) == [600])
    }

    private static func removeStore(at url: URL) {
        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(at: URL(filePath: url.path() + suffix))
        }
    }
}
