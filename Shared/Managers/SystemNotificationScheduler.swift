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
            Log.settings.error("Notification permission request failed: \(error)")
            return false
        }
    }
}
