import Foundation

/// Everything the rules need, read once: the task data, the settings and the calendar.
public struct Snapshot: Sendable {
    public let data: TaskData
    public let settings: SettingsValue
    public let calendar: Calendar
    public let engine: ScheduleEngine
    public let activity: ActivityLog
    public let statusRules: StatusRules

    public init(data: TaskData, settings: SettingsValue, calendar: Calendar) {
        self.data = data
        self.settings = settings
        self.calendar = calendar
        self.engine = ScheduleEngine(data: data, calendar: calendar)
        self.activity = ActivityLog(data: data)
        self.statusRules = StatusRules(activity: activity, parts: settings.parts, calendar: calendar)
    }

    public var parts: PartSettings { settings.parts }

    public func status(of occurrence: Occurrence, now: Date) -> Status {
        statusRules.status(of: occurrence, now: now)
    }

    public func occurrences(on day: DayKey) -> [Occurrence] {
        engine.occurrences(on: day)
    }
}
