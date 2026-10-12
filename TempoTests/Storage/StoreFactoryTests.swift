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

    /// A store written by version 1 opens under the current version with its data, and its settings row gets the
    /// default theme color and appearance (SPEC T-33, T-34, ios.md §6).
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
        #expect(settings.appearance == .system)
    }

    /// A store written by version 2 keeps its data and theme color, and gets System as its appearance (SPEC T-34).
    @Test func versionTwoStoreMigratesWithItsData() throws {
        let url = try StoreFactory.storeURL(fileName: "Tempo-v2-\(UUID().uuidString).store")
        defer { Self.removeStore(at: url) }
        let taskID = UUID()
        do {
            let schema = Schema(versionedSchema: SchemaV2.self)
            let old = try ModelContainer(
                for: schema, configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none))
            let context = ModelContext(old)
            let task = SchemaV2.TaskRecord()
            task.id = taskID
            task.title = "Read"
            context.insert(task)
            let settings = SchemaV2.SettingsRecord()
            settings.id = SwiftDataTaskStore.settingsID
            settings.tintColor = "#1E90FF"
            context.insert(settings)
            try context.save()
        }

        let store = SwiftDataTaskStore(container: try StoreFactory.make(url: url), clock: TestEnvironment.clock())
        #expect(try store.task(id: taskID)?.title == "Read")
        let settings = try #require(try store.settings())
        #expect(settings.tintColor == .custom(red: 30, green: 144, blue: 255))
        #expect(settings.appearance == .system)
    }

    /// A store written by version 3 keeps its data and gets the version 4 defaults: no notes, only Morning's part-start
    /// summary, and the Gentle missed style (SPEC T-37).
    @Test func versionThreeStoreMigratesWithItsData() throws {
        let url = try StoreFactory.storeURL(fileName: "Tempo-v3-\(UUID().uuidString).store")
        defer { Self.removeStore(at: url) }
        let taskID = UUID()
        do {
            let schema = Schema(versionedSchema: SchemaV3.self)
            let old = try ModelContainer(
                for: schema, configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none))
            let context = ModelContext(old)
            let task = SchemaV3.TaskRecord()
            task.id = taskID
            task.title = "Read"
            task.type = "duration"
            task.startDay = 20_261_001
            context.insert(task)
            let settings = SchemaV3.SettingsRecord()
            settings.id = SwiftDataTaskStore.settingsID
            settings.notifyPartStart = false
            settings.appearance = "dark"
            settings.tintColor = "teal"
            context.insert(settings)
            try context.save()
        }

        let store = SwiftDataTaskStore(container: try StoreFactory.make(url: url), clock: TestEnvironment.clock())
        let task = try #require(try store.task(id: taskID))
        #expect(task.title == "Read")
        #expect(task.type == .duration)
        #expect(task.startDay == DayKey(year: 2026, month: 10, day: 1))
        #expect(task.notes == nil)
        let settings = try #require(try store.settings())
        #expect(settings.appearance == .dark)
        #expect(settings.tintColor == .preset(.teal))
        #expect(settings.partStartSummaries == [.morning])
        #expect(settings.missedStyle == .gentle)
    }

    /// SPEC §4.1, §4.5 (T-37): notes and the new settings columns round-trip, and an unreadable missed style is Gentle.
    @Test func newColumnsRoundTrip() throws {
        let clock = TestEnvironment.clock()
        let container = try StoreFactory.make(inMemory: true)
        let store = SwiftDataTaskStore(container: container, clock: clock)
        let task = try store.save(
            TaskValue(
                title: "Renew passport", type: .oneTime, date: TestEnvironment.today, notes: "Form B",
                createdAt: clock.now))
        #expect(try store.task(id: task.id)?.notes == "Form B")

        var settings = SettingsValue.defaults
        settings.partStartSummaries = [.noon, .night]
        settings.missedStyle = .strict
        try store.save(settings)
        #expect(try store.settings()?.partStartSummaries == [.noon, .night])
        #expect(try store.settings()?.missedStyle == .strict)

        let context = ModelContext(container)
        let id = SwiftDataTaskStore.settingsID
        let record = try #require(
            try context.fetch(FetchDescriptor<SchemaV4.SettingsRecord>(predicate: #Predicate { $0.id == id })).first)
        record.missedStyle = "harsh"
        try context.save()
        #expect(try store.settings()?.missedStyle == .gentle)
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
