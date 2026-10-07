/// Every live row of the four task tables, read together so rules can work on one consistent copy.
public struct TaskData: Hashable, Sendable {
    public var tasks: [TaskValue]
    public var schedules: [ScheduleValue]
    public var completions: [CompletionValue]
    public var timeEntries: [TimeEntryValue]

    public init(
        tasks: [TaskValue] = [],
        schedules: [ScheduleValue] = [],
        completions: [CompletionValue] = [],
        timeEntries: [TimeEntryValue] = []
    ) {
        self.tasks = tasks
        self.schedules = schedules
        self.completions = completions
        self.timeEntries = timeEntries
    }
}
