import Foundation
import UserNotifications

/// `NotificationScheduling` on `UNUserNotificationCenter` (ios.md §10).
struct SystemNotificationScheduler: NotificationScheduling {
    func permission() async -> NotificationPermission {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized, .provisional, .ephemeral: return .allowed
        @unknown default: return .denied
        }
    }

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            Log.reminders.error("Notification permission request failed: \(error)")
            return false
        }
    }

    func replacePending(with notifications: [ScheduledNotification], calendar: Calendar) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for notification in notifications {
            let content = UNMutableNotificationContent()
            content.title = notification.title
            content.body = notification.body
            content.sound = .default
            content.userInfo = ["url": notification.url.absoluteString]
            if let category = notification.categoryIdentifier { content.categoryIdentifier = category }
            // Components without a time zone, so the reminder floats with local time like the tasks (ios.md §10).
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notification.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            do {
                try await center.add(
                    UNNotificationRequest(identifier: notification.id, content: content, trigger: trigger))
            } catch {
                Log.reminders.error("Couldn't schedule \(notification.id, privacy: .public): \(error)")
            }
        }
    }

    /// Registers the timer alert's Stop and Keep going actions.
    static func registerCategories() {
        let stop = UNNotificationAction(
            identifier: NotificationCategory.stop, title: String(localized: "Stop"), options: [.foreground])
        let keepGoing = UNNotificationAction(
            identifier: NotificationCategory.keepGoing, title: String(localized: "Keep going"), options: [])
        let category = UNNotificationCategory(
            identifier: NotificationCategory.timerAlert, actions: [stop, keepGoing], intentIdentifiers: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
