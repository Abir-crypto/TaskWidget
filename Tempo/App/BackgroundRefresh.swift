import BackgroundTasks
import Foundation

/// The background refresh that tops up the notification plan while the app isn't open (SPEC F-07, ios.md §10).
enum BackgroundRefresh {
    static let identifier = "com.akumatech.tempo.refresh"

    /// Asks the system to run the refresh again, no sooner than an hour from now.
    static func schedule(after now: Date) {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = now.addingTimeInterval(60 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // The simulator doesn't run background tasks; this is expected there.
            Log.reminders.info("Background refresh not scheduled: \(error)")
        }
    }
}
