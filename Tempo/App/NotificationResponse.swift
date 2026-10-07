import Foundation

/// What the user did with a notification: tapped it, or chose one of its actions.
struct NotificationResponse: Hashable, Sendable {
    /// `STOP`, `KEEP_GOING`, or the system's identifier for a plain tap.
    let actionIdentifier: String
    /// The link stored in the notification.
    let url: URL?
}
