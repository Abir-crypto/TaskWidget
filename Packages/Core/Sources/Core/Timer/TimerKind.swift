/// The stored kinds of timer (SPEC §4.6).
public enum TimerKind: String, Codable, Sendable {
    /// Started from the Timer widget, with no habit; the habit is chosen at Done.
    case generic
    /// Started with ▶ on a duration habit.
    case habit
}
