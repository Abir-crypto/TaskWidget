import Foundation

/// When widgets must redraw (SPEC §5.10, F-17): now, each part's start, an hour before and at each fixed time,
/// and midnight, for today and tomorrow. Counting text such as clocks updates itself in between.
public enum TimelinePlanner {
    /// A habit timer's progress, so the Now widget can redraw the moment the target is reached.
    public struct TimerGoal: Sendable {
        public let state: TimerState
        /// Seconds already logged to the habit on the timer's day, before this timer.
        public let loggedSeconds: Int
        public let targetMinutes: Int

        public init(state: TimerState, loggedSeconds: Int, targetMinutes: Int) {
            self.state = state
            self.loggedSeconds = loggedSeconds
            self.targetMinutes = targetMinutes
        }
    }

    /// An hour before a fixed time, widgets start pointing at it (SPEC §5.6 rule 1).
    public static let fixedLeadMinutes = 60

    /// Every update moment from `now` (included) to the end of tomorrow, earliest first, without duplicates.
    public static func moments(from now: Date, snapshot: Snapshot, timerGoal: TimerGoal? = nil) -> [Date] {
        let calendar = snapshot.calendar
        let today = DayKey(now, calendar: calendar)
        let tomorrow = today.adding(days: 1, in: calendar)
        var moments: Set<Date> = [now]

        for day in [today, tomorrow] {
            for part in DayPart.allCases {
                moments.insert(day.date(atMinute: snapshot.parts.start(of: part), in: calendar))
            }
            for occurrence in snapshot.occurrences(on: day) {
                guard let minute = occurrence.timing.fixedMinute else { continue }
                let fixed = day.date(atMinute: minute, in: calendar)
                moments.insert(fixed)
                moments.insert(fixed.addingTimeInterval(TimeInterval(-fixedLeadMinutes * 60)))
            }
            // Midnight: the start of the next day.
            moments.insert(day.adding(days: 1, in: calendar).startDate(in: calendar))
        }

        if let goal = timerGoal, let reached = targetReached(goal, now: now) {
            moments.insert(reached)
        }

        let end = tomorrow.adding(days: 1, in: calendar).startDate(in: calendar)
        return moments.filter { $0 >= now && $0 <= end }.sorted()
    }

    /// When a running habit timer brings the day's time up to the target, or `nil` if paused or already there.
    public static func targetReached(_ goal: TimerGoal, now: Date) -> Date? {
        guard TimerRules.isRunning(goal.state) else { return nil }
        let remaining =
            TimeInterval(goal.targetMinutes * 60 - goal.loggedSeconds) - TimerRules.elapsed(goal.state, now: now)
        guard remaining > 0 else { return nil }
        return now.addingTimeInterval(remaining)
    }

    /// The moment the next day starts, which is when widgets ask for a new timeline.
    public static func nextMidnight(after now: Date, calendar: Calendar) -> Date {
        DayKey(now, calendar: calendar).adding(days: 1, in: calendar).startDate(in: calendar)
    }
}
