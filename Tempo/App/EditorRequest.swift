import Core
import Foundation

/// Opens the task editor (SPEC F-15): a new task with presets, or an existing task.
struct EditorRequest: Identifiable, Hashable {
    enum Mode: Hashable {
        /// A new task, preset with a day and a type where the opener knows them.
        case new(day: DayKey?, type: TaskType?)
        case edit(taskID: UUID)
    }

    let id = UUID()
    let mode: Mode

    static func new(day: DayKey? = nil, type: TaskType? = nil) -> EditorRequest {
        EditorRequest(mode: .new(day: day, type: type))
    }

    static func edit(_ taskID: UUID) -> EditorRequest {
        EditorRequest(mode: .edit(taskID: taskID))
    }
}
