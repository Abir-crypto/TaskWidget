import Foundation

/// How editing a task's timing, weekdays or target is written to `schedules` (SPEC §4.2, F-03).
public enum ScheduleHistory {
    /// The one row to write for an edit.
    public enum Write: Hashable, Sendable {
        case insert(ScheduleValue)
        case update(ScheduleValue)

        public var schedule: ScheduleValue {
            switch self {
            case .insert(let schedule), .update(let schedule): schedule
            }
        }
    }

    /// The row to write when a task's schedule is edited on `today`, or `nil` when nothing changes.
    ///
    /// - A one-time task's single row is updated in place.
    /// - A habit that hasn't started yet has its first row updated in place.
    /// - A habit that already has a row starting today has that row updated, so several edits on one day
    ///   leave one row.
    /// - Otherwise a new row starts today, and earlier days keep the schedule they had.
    public static func edit(
        task: TaskValue,
        schedules: [ScheduleValue],
        timing: Timing,
        weekdays: Weekdays,
        targetMinutes: Int?,
        today: DayKey,
        now: Date
    ) -> Write? {
        let live = schedules.filter { $0.taskID == task.id && $0.deletedAt == nil }
            .sorted { $0.effectiveFrom < $1.effectiveFrom }

        func changed(_ row: ScheduleValue) -> ScheduleValue {
            var row = row
            row.timing = timing
            row.weekdays = weekdays
            row.targetMinutes = targetMinutes
            return row
        }

        let current = live.last { $0.effectiveFrom <= today } ?? live.first
        if let current, current.timing == timing, current.weekdays == weekdays, current.targetMinutes == targetMinutes,
            current == live.last
        {
            return nil
        }

        if !task.type.isHabit {
            guard let row = live.first else {
                return .insert(
                    ScheduleValue(
                        taskID: task.id, effectiveFrom: .distantPast, timing: timing, weekdays: .none,
                        targetMinutes: nil, createdAt: now))
            }
            return .update(changed(row))
        }
        if let start = task.startDay, start > today, let first = live.first {
            return .update(changed(first))
        }
        if let todays = live.first(where: { $0.effectiveFrom == today }) {
            return .update(changed(todays))
        }
        return .insert(
            ScheduleValue(
                taskID: task.id, effectiveFrom: today, timing: timing, weekdays: weekdays,
                targetMinutes: targetMinutes, createdAt: now))
    }
}
