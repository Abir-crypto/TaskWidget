import Core

/// What happened when a habit timer was finished (SPEC F-06).
enum TimerSaveResult: Equatable {
    /// The time was saved as this entry.
    case saved(TimeEntryValue)
    /// Less than a minute: nothing was saved.
    case tooShort
}
