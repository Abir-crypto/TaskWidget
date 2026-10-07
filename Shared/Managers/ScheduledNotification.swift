import Foundation

/// A notification ready for the system: its id, fire time, words, link and category (ios.md §10).
struct ScheduledNotification: Hashable, Sendable {
    let id: String
    let fireDate: Date
    let title: String
    let body: String
    let url: URL
    /// `TIMER_ALERT` for the running-timer alert, which has Stop and Keep going.
    let categoryIdentifier: String?
}
