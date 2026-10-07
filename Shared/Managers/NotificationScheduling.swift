import Foundation

/// The system notification center, behind a protocol so previews and tests can use a fake (ios.md §4).
protocol NotificationScheduling: Sendable {
    func permission() async -> NotificationPermission
    /// Asks the system for permission. Returns whether notifications are now allowed.
    func requestPermission() async -> Bool
    /// Replaces every pending notification the app manages with these, firing in the calendar's local time.
    func replacePending(with notifications: [ScheduledNotification], calendar: Calendar) async
}
