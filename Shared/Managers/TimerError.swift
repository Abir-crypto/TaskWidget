/// Why a timer action was refused (SPEC F-06).
enum TimerError: Error, Equatable {
    /// A timer already exists; it has to be finished or discarded first.
    case timerExists
    /// There's no timer to act on.
    case noTimer
    /// The habit can't be timed today (not a duration habit, or not live today).
    case cantTimeHabit
}
