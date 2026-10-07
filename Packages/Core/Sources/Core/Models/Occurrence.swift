import Foundation

/// A task on one specific day (SPEC §5.3). Computed from the task and its schedule, never stored.
public struct Occurrence: Identifiable, Hashable, Sendable {
    public let task: TaskValue
    public let day: DayKey
    /// The schedule in effect on `day`.
    public let schedule: ScheduleValue

    public init(task: TaskValue, day: DayKey, schedule: ScheduleValue) {
        self.task = task
        self.day = day
        self.schedule = schedule
    }

    /// `<task_id>_<day>`, as used by the missed popup's seen list (SPEC §5.3, §4.6).
    public var id: String { Occurrence.id(taskID: task.id, day: day) }

    public static func id(taskID: UUID, day: DayKey) -> String {
        "\(taskID.uuidString.lowercased())_\(day.rawValue)"
    }

    public var timing: Timing { schedule.timing }
    public var type: TaskType { task.type }

    /// The window during which the occurrence is Open (SPEC §5.2).
    public func window(parts: PartSettings) -> Range<Int> {
        switch schedule.timing {
        case .part(let part): parts.window(of: part)
        case .fixed(let minute): parts.window(of: parts.part(containing: minute))
        case .anytime: 0..<DayKey.minutesPerDay
        }
    }

    /// The part the occurrence belongs to, or `nil` for Anytime. Fixed times belong to the part that contains them.
    public func part(parts: PartSettings) -> DayPart? {
        switch schedule.timing {
        case .part(let part): part
        case .fixed(let minute): parts.part(containing: minute)
        case .anytime: nil
        }
    }
}
