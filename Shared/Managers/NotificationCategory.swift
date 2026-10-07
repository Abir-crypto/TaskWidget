/// Notification categories and actions (ios.md §2, §10).
enum NotificationCategory {
    /// The running-timer alert, with Stop and Keep going.
    static let timerAlert = "TIMER_ALERT"
    /// Pauses the timer and opens the timer screen.
    static let stop = "STOP"
    /// Dismisses the alert; it comes back after another alert period.
    static let keepGoing = "KEEP_GOING"
}
