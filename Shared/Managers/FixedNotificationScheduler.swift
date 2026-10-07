import Foundation

/// A notification center that reports a set permission and records what would be scheduled, for previews,
/// UI tests and unit tests.
final class FixedNotificationScheduler: NotificationScheduling, @unchecked Sendable {
    private let lock = NSLock()
    private var current: NotificationPermission
    /// What `requestPermission` turns the permission into.
    private let answer: NotificationPermission
    private var pendingNotifications: [ScheduledNotification] = []
    private var replacements = 0

    init(permission: NotificationPermission, answer: NotificationPermission = .allowed) {
        self.current = permission
        self.answer = answer
    }

    /// The notifications currently "pending".
    var pending: [ScheduledNotification] { lock.withLock { pendingNotifications } }
    /// How many times the pending set was replaced.
    var replaceCount: Int { lock.withLock { replacements } }

    func setPermission(_ permission: NotificationPermission) {
        lock.withLock { current = permission }
    }

    func permission() async -> NotificationPermission {
        lock.withLock { current }
    }

    func requestPermission() async -> Bool {
        lock.withLock {
            current = answer
            return answer == .allowed
        }
    }

    func replacePending(with notifications: [ScheduledNotification], calendar: Calendar) async {
        lock.withLock {
            pendingNotifications = notifications
            replacements += 1
        }
    }
}
