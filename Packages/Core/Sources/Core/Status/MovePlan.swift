/// What Move to tomorrow (or Move to next day) does to a one-time task (SPEC F-04).
public enum MovePlan: Hashable, Sendable {
    /// The task isn't missed: its date changes to `day`.
    case moveDate(to: DayKey)
    /// The task is Missed today: it stays on today as missed, and a copy is created for `day`.
    case copy(to: DayKey)
}
