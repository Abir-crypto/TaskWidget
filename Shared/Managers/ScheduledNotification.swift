import Core
import Foundation

/// A notification ready for the system: its id, fire time, words, link and category (ios.md §10).
struct ScheduledNotification: Hashable, Sendable {
    let id: String
    let fireDate: Date
    let title: String
    let body: String
    let url: URL
    /// `TIMER_ALERT` for the running-timer alert, which has Stop and Keep going; a snooze category for fixed-time
    /// and ending-soon reminders that can be snoozed.
    let categoryIdentifier: String?
    /// What the Snooze buttons need, for reminders that have them (SPEC F-07).
    var snooze: SnoozeTarget? = nil
}
