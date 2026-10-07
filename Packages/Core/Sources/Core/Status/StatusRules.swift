import Foundation

/// Computes an occurrence's status from the clock (SPEC §5.4).
public struct StatusRules: Sendable {
    public let activity: ActivityLog
    public let parts: PartSettings
    public let calendar: Calendar

    public init(activity: ActivityLog, parts: PartSettings, calendar: Calendar) {
        self.activity = activity
        self.parts = parts
        self.calendar = calendar
    }

    /// SPEC §5.4, step by step.
    public func status(of occurrence: Occurrence, now: Date) -> Status {
        status(of: occurrence, at: LocalTime(now, calendar: calendar))
    }

    public func status(of occurrence: Occurrence, at now: LocalTime) -> Status {
        if isDone(occurrence) { return .done }
        if occurrence.day > now.day { return .upcoming }
        if occurrence.day == now.day {
            let window = occurrence.window(parts: parts)
            if now.minute < window.lowerBound { return .upcoming }
            if now.minute < window.upperBound { return .open }
        }
        // The part has ended, or it's a past day.
        if occurrence.type == .duration, minutes(of: occurrence) > 0 { return .short }
        return .missed
    }

    /// Completed for one-time and progress tasks; minutes at or above the day's target for duration habits.
    public func isDone(_ occurrence: Occurrence) -> Bool {
        switch occurrence.type {
        case .oneTime, .progress:
            return activity.isCompleted(taskID: occurrence.task.id, day: occurrence.day)
        case .duration:
            guard let target = occurrence.schedule.targetMinutes else { return false }
            return minutes(of: occurrence) >= target
        }
    }

    /// Minutes logged to the occurrence's habit on its day.
    public func minutes(of occurrence: Occurrence) -> Int {
        activity.minutes(taskID: occurrence.task.id, day: occurrence.day)
    }
}
