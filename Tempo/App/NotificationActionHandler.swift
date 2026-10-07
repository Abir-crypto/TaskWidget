import Foundation

/// Acts on notification taps and the timer alert's actions (SPEC F-06, F-07, ios.md §10).
@MainActor
enum NotificationActionHandler {
    static func handle(_ response: NotificationResponse, dependencies: AppDependencies, router: NavigationRouter) {
        switch response.actionIdentifier {
        case NotificationCategory.stop:
            // Stop pauses the timer and opens the timer screen.
            dependencies.timer.pause()
            router.open(.timer)
        case NotificationCategory.keepGoing:
            // The alert comes back one period later; rebuilding schedules it.
            Task { await dependencies.reminders.rebuild() }
        default:
            router.open(response.url.map(DeepLink.init(url:)) ?? .today())
        }
    }
}
