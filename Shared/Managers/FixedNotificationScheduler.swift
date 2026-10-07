import Foundation

/// A notification center that reports a set permission, for previews, UI tests and unit tests.
final class FixedNotificationScheduler: NotificationScheduling, @unchecked Sendable {
    private let lock = NSLock()
    private var current: NotificationPermission
    /// What `requestPermission` turns the permission into.
    private let answer: NotificationPermission

    init(permission: NotificationPermission, answer: NotificationPermission = .allowed) {
        self.current = permission
        self.answer = answer
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
}
