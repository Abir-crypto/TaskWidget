import Core
import Foundation

/// Opens the task picker (SPEC F-06): to save a finished generic timer's time, or to move an entry the
/// confirmation's "Change task" points at.
struct TaskPickerRequest: Identifiable, Hashable {
    let id = UUID()
    let timer: FinishedTimer
    /// Set when moving an already saved entry to another habit.
    var movingEntryID: UUID?
}
