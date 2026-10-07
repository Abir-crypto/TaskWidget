import Core
import Foundation

/// What the Now widget shows (SPEC F-21): timer mode while a habit timer exists, otherwise the list.
enum NowWidgetContent: Hashable {
    case list(NowList)
    case timer(NowTimer)

    /// Rows that fit in the large widget, headers included.
    static let maximumRows = 8

    init(snapshot: WidgetSnapshot, at date: Date) {
        if let timer = snapshot.timer, timer.kind == .habit, let habitID = timer.habitID {
            let core = snapshot.core
            self = .timer(
                NowTimer(
                    habitID: habitID, title: snapshot.timerHabitTitle ?? String(localized: "Timer"),
                    clock: TimerClockValue(state: timer),
                    loggedSeconds: core.activity.seconds(taskID: habitID, day: timer.startDay),
                    targetMinutes: core.engine.schedule(for: habitID, on: timer.startDay)?.targetMinutes,
                    elapsedSeconds: Int(TimerRules.elapsed(timer, now: date))))
        } else {
            self = .list(NowList(snapshot: snapshot, at: date))
        }
    }
}
