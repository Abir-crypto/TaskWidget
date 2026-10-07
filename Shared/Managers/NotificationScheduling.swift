/// The system notification center, behind a protocol so previews and tests can use a fake (ios.md §4).
protocol NotificationScheduling: Sendable {
    func permission() async -> NotificationPermission
    /// Asks the system for permission. Returns whether notifications are now allowed.
    func requestPermission() async -> Bool
}
