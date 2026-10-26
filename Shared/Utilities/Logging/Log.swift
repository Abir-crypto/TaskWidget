import os

/// `os.Logger` categories, one per area (ios.md §14).
enum Log {
    private static let subsystem = "com.akumatech.tempo"

    static let storage = Logger(subsystem: subsystem, category: "Storage")
    static let deviceState = Logger(subsystem: subsystem, category: "DeviceState")
    static let settings = Logger(subsystem: subsystem, category: "Settings")
    static let tasks = Logger(subsystem: subsystem, category: "Tasks")
    static let refresh = Logger(subsystem: subsystem, category: "Refresh")
    static let reminders = Logger(subsystem: subsystem, category: "Reminders")
    static let liveActivity = Logger(subsystem: subsystem, category: "LiveActivity")
}
