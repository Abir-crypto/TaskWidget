import Core
import Foundation

/// Opens the task picker for a finished generic timer (SPEC F-06, F-09).
struct TaskPickerRequest: Identifiable, Hashable {
    let id = UUID()
    let timer: FinishedTimer
}
