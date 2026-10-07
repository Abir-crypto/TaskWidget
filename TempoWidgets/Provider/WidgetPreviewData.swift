import Core
import Foundation

/// Snapshots and timers for widget previews.
extension WidgetSnapshot {
    static func preview(timer: TimerState?, habitTitle: String? = nil, data: TaskData = TaskData()) -> WidgetSnapshot {
        WidgetSnapshot(
            core: Snapshot(data: data, settings: .defaults, calendar: .autoupdatingCurrent), timer: timer,
            timerHabitTitle: habitTitle)
    }
}

extension TimerState {
    static func previewGeneric(running: Bool) -> TimerState {
        TimerState(
            kind: .generic, habitID: nil, startDay: DayKey(.now, calendar: .autoupdatingCurrent),
            accumulatedSeconds: 312,
            segmentStart: running ? .now : nil)
    }

    static func previewHabit(running: Bool) -> TimerState {
        TimerState(
            kind: .habit, habitID: UUID(), startDay: DayKey(.now, calendar: .autoupdatingCurrent),
            accumulatedSeconds: 700,
            segmentStart: running ? .now : nil)
    }
}
