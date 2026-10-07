import Core
import Foundation

/// The confirmation after a timer's time is saved, or the note that nothing was saved (SPEC F-06).
struct TimerToast: Identifiable, Hashable {
    let id = UUID()
    /// "Added 18 min to Read · 28 of 30 min today" or "Less than a minute, nothing saved."
    let message: String
    /// The saved entry, for Undo and Change task. `nil` when nothing was saved.
    let entry: TimeEntryValue?
}
