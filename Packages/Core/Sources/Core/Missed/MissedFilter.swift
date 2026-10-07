import Foundation

/// Sort and filters for the Missed tab's Earlier section (SPEC F-08).
public struct MissedFilter: Hashable, Sendable {
    public var sort: MissedSort
    public var dateRange: MissedDateRange
    /// The task types shown. All three by default.
    public var types: Set<TaskType>
    /// The parts shown; fixed-time tasks count under their part. All five by default.
    public var parts: Set<MissedPartFilter>
    /// Only this task, when set.
    public var taskID: UUID?

    public init(
        sort: MissedSort = .newestFirst,
        dateRange: MissedDateRange = .all,
        types: Set<TaskType> = Set(TaskType.allCases),
        parts: Set<MissedPartFilter> = Set(MissedPartFilter.allCases),
        taskID: UUID? = nil
    ) {
        self.sort = sort
        self.dateRange = dateRange
        self.types = types
        self.parts = parts
        self.taskID = taskID
    }

    /// Newest first, every date, type and part, any task.
    public static let `default` = MissedFilter()

    /// Whether any filter differs from the default, which is when Clear filters appears. Sorting isn't a filter.
    public var isActive: Bool {
        dateRange != .all || types != Set(TaskType.allCases) || parts != Set(MissedPartFilter.allCases)
            || taskID != nil
    }

    /// The filter with every filter reset and the sort order kept.
    public var cleared: MissedFilter {
        MissedFilter(sort: sort)
    }
}
