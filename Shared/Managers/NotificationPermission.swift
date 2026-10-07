/// Whether the user lets the app send notifications (SPEC F-07, F-16).
enum NotificationPermission: Equatable, Sendable {
    /// Never asked.
    case notDetermined
    /// Refused, or turned off in the system settings.
    case denied
    /// Allowed, including provisional and ephemeral authorization.
    case allowed
}
