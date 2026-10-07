import Foundation

/// Completions and time entries, indexed by task and day.
public struct ActivityLog: Hashable, Sendable {
    private struct Key: Hashable, Sendable {
        let taskID: UUID
        let day: DayKey
    }

    private let completed: Set<Key>
    private let secondsByKey: [Key: Int]
    /// Every live time entry, oldest first.
    public let timeEntries: [TimeEntryValue]
    /// Every live completion.
    public let completions: [CompletionValue]

    public init(completions: [CompletionValue], timeEntries: [TimeEntryValue]) {
        let liveCompletions = completions.filter { $0.deletedAt == nil }
        let liveEntries = timeEntries.filter { $0.deletedAt == nil }
        self.completions = liveCompletions
        self.timeEntries = liveEntries
        self.completed = Set(liveCompletions.map { Key(taskID: $0.taskID, day: $0.day) })
        var seconds: [Key: Int] = [:]
        for entry in liveEntries {
            seconds[Key(taskID: entry.taskID, day: entry.day), default: 0] += entry.seconds
        }
        self.secondsByKey = seconds
    }

    public init(data: TaskData) {
        self.init(completions: data.completions, timeEntries: data.timeEntries)
    }

    /// A (task, day) pair is done if at least one live completion exists for it (SPEC §4.3).
    public func isCompleted(taskID: UUID, day: DayKey) -> Bool {
        completed.contains(Key(taskID: taskID, day: day))
    }

    /// The total seconds logged to a habit on a day.
    public func seconds(taskID: UUID, day: DayKey) -> Int {
        secondsByKey[Key(taskID: taskID, day: day)] ?? 0
    }

    /// Whole minutes logged on a day, rounded down from the total seconds (SPEC §5.5, F-05).
    public func minutes(taskID: UUID, day: DayKey) -> Int {
        seconds(taskID: taskID, day: day) / 60
    }

    /// Whether the task has any completion or time on the day.
    public func hasActivity(taskID: UUID, day: DayKey) -> Bool {
        isCompleted(taskID: taskID, day: day) || seconds(taskID: taskID, day: day) > 0
    }
}
