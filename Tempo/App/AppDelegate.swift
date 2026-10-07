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

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse
    ) async {
        let url = (response.notification.request.content.userInfo["url"] as? String).flatMap(URL.init(string:))
        let received = NotificationResponse(actionIdentifier: response.actionIdentifier, url: url)
        await MainActor.run { self.receive(received) }
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
