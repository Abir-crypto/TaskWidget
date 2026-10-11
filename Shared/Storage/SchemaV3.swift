import Foundation
import SwiftData

/// Version 3 of the store (T-34): version 2 plus the settings row's appearance, `appearance` (SPEC §4.5, F-28).
/// It migrates from version 2 with a lightweight stage (ios.md §6).
///
/// Records have plain properties with defaults and no relationships. Tables link through `UUID` fields,
/// enums are stored as their SPEC strings, and day keys as `Int`. Records never leave `Shared/Storage/`.
enum SchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TaskRecord.self, ScheduleRecord.self, CompletionRecord.self, TimeEntryRecord.self, SettingsRecord.self]
    }

    /// SPEC §4.1 `tasks`.
    @Model final class TaskRecord {
        var id: UUID = UUID()
        var title: String = ""
        var type: String = "one_time"  // one_time | progress | duration
        var date: Int? = nil  // one-time: yyyymmdd
        var startDay: Int? = nil  // habits
        var lengthDays: Int? = nil  // nil = ongoing
        var endedOn: Int? = nil
        var createdAt: Date = Date(timeIntervalSinceReferenceDate: 0)
        var updatedAt: Date = Date(timeIntervalSinceReferenceDate: 0)
        var deletedAt: Date? = nil
        init() {}
    }

    /// SPEC §4.2 `schedules`.
    @Model final class ScheduleRecord {
        var id: UUID = UUID()
        var taskID: UUID = UUID()
        var effectiveFrom: Int = 0  // yyyymmdd; 0 for one-time tasks
        var timing: String = "anytime"  // fixed | part | anytime
        var fixedMinute: Int? = nil
        var part: String? = nil  // morning | noon | evening | night
        var weekdays: Int = 0  // Mon=1 … Sun=64
        var targetMinutes: Int? = nil
        var createdAt: Date = Date(timeIntervalSinceReferenceDate: 0)
        var updatedAt: Date = Date(timeIntervalSinceReferenceDate: 0)
        var deletedAt: Date? = nil
        init() {}
    }

    /// SPEC §4.3 `completions`.
    @Model final class CompletionRecord {
        var id: UUID = UUID()
        var taskID: UUID = UUID()
        var day: Int = 0
        var createdAt: Date = Date(timeIntervalSinceReferenceDate: 0)
        var updatedAt: Date = Date(timeIntervalSinceReferenceDate: 0)
        var deletedAt: Date? = nil
        init() {}
    }

    /// SPEC §4.4 `time_entries`.
    @Model final class TimeEntryRecord {
        var id: UUID = UUID()
        var taskID: UUID = UUID()
        var day: Int = 0
        var seconds: Int = 0
        var source: String = "manual"  // timer | manual
        var createdAt: Date = Date(timeIntervalSinceReferenceDate: 0)
        var updatedAt: Date = Date(timeIntervalSinceReferenceDate: 0)
        var deletedAt: Date? = nil
        init() {}
    }

    /// SPEC §4.5 `settings`: a single row with a fixed id.
    @Model final class SettingsRecord {
        var id: UUID = UUID()
        var morningStart: Int = 360
        var noonStart: Int = 720
        var eveningStart: Int = 1020
        var nightStart: Int = 1260
        var notifyPartStart: Bool = true
        var notifyEndingSoon: Bool = true
        var endingSoonLead: Int = 30
        var notifyFixed: Bool = true
        var fixedLead: Int = 10
        var notifyRecap: Bool = true
        var recapMinute: Int = 1410
        var notifyTimer: Bool = true
        var timerAlertMinutes: Int = 120
        var hideLockScreenTitles: Bool = false
        var tintColor: String = "blue"  // a ThemePreset name or #RRGGBB
        var appearance: String = "system"  // system | dark | light
        var updatedAt: Date = Date(timeIntervalSinceReferenceDate: 0)
        init() {}
    }
}
