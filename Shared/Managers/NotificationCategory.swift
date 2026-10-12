import Core

/// Notification categories and actions (ios.md §2, §10).
enum NotificationCategory {
    /// The running-timer alert, with Stop and Keep going.
    static let timerAlert = "TIMER_ALERT"
    /// Pauses the timer and opens the timer screen.
    static let stop = "STOP"
    /// Dismisses the alert; it comes back after another alert period.
    static let keepGoing = "KEEP_GOING"

    /// A fixed-time or ending-soon reminder with both Snooze buttons (SPEC F-07).
    static let snoozeBoth = "REMINDER_SNOOZE_BOTH"
    /// A reminder with only Snooze 15 min, when 1 hour would land too close to the part's end.
    static let snoozeQuarter = "REMINDER_SNOOZE_15"
    /// Snooze 15 min, a background action that doesn't open the app.
    static let snooze15 = "SNOOZE_15"
    /// Snooze 1 hour, a background action that doesn't open the app.
    static let snooze60 = "SNOOZE_60"

    /// The category that carries a reminder's Snooze options, chosen when it's planned (ios.md §10).
    static func snoozeCategory(for options: [SnoozeOption]) -> String? {
        switch Set(options) {
        case [.fifteenMinutes, .oneHour]: snoozeBoth
        case [.fifteenMinutes]: snoozeQuarter
        default: nil
        }
    }
}
