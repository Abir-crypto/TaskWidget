import UIKit
import UserNotifications

/// The notification center's delegate (ios.md §10): shows notifications while the app is open, and passes
/// taps and actions to the app once it's ready.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    /// Set by the app once its dependencies exist. Responses that arrive earlier wait until then.
    var onResponse: ((NotificationResponse) -> Void)? {
        didSet { deliverWaitingResponses() }
    }
    private var waiting: [NotificationResponse] = []

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        SystemNotificationScheduler.registerCategories()
        return true
    }

    // The completion-handler forms, with each handler called on the main actor: the system calls the async forms'
    // handlers off the main thread, and tapping a notification then crashed UIKit's state restoration (T-32).
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping @Sendable (UNNotificationPresentationOptions) -> Void
    ) {
        Task { @MainActor in completionHandler([.banner, .list, .sound]) }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping @Sendable () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        // Snooze runs in the background without the app's screens, so it uses its own managers, like a widget
        // button, and finishes before the system suspends the app (SPEC F-07, ios.md §10).
        if let snooze = SnoozeRequest(actionIdentifier: response.actionIdentifier, userInfo: userInfo) {
            Task { @MainActor in
                do {
                    let environment = try IntentEnvironment.make()
                    await environment.refresh.reminders?.snooze(snooze)
                } catch {
                    Log.reminders.error("Couldn't snooze: \(error)")
                }
                completionHandler()
            }
            return
        }
        let url = (userInfo["url"] as? String).flatMap(URL.init(string:))
        let received = NotificationResponse(actionIdentifier: response.actionIdentifier, url: url)
        Task { @MainActor in
            self.receive(received)
            completionHandler()
        }
    }

    @MainActor
    private func receive(_ response: NotificationResponse) {
        if let onResponse {
            onResponse(response)
        } else {
            waiting.append(response)
        }
    }

    @MainActor
    private func deliverWaitingResponses() {
        guard let onResponse else { return }
        let responses = waiting
        waiting = []
        responses.forEach(onResponse)
    }
}
