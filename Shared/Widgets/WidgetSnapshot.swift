import Core
import Foundation

/// Everything a widget draws from, read once per timeline: the task data, the settings and the timer
/// (ios.md §9). Each entry recalculates statuses for its own moment.
struct WidgetSnapshot: Sendable {
    let core: Snapshot
    let timer: TimerState?
    /// The timed habit's title, when the timer is a habit timer.
    let timerHabitTitle: String?

    var calendar: Calendar { core.calendar }

    /// The day plan at a moment (SPEC F-10 order).
    func plan(at date: Date) -> DayPlan {
        DayPlan(day: DayKey(date, calendar: calendar), snapshot: core, now: date)
    }

    /// An empty snapshot, for placeholders.
    static func empty(calendar: Calendar) -> WidgetSnapshot {
        WidgetSnapshot(
            core: Snapshot(data: TaskData(), settings: .defaults, calendar: calendar), timer: nil, timerHabitTitle: nil)
    }
}
