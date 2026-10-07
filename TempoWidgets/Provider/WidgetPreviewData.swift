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

extension TaskData {
    /// A few of today's tasks for the Now widget's preview.
    static var nowPreview: TaskData {
        let calendar = Calendar.autoupdatingCurrent
        let today = DayKey(.now, calendar: calendar)
        var data = TaskData()
        for (index, item) in [
            ("Call the bank", Timing.part(.noon)), ("Interview", .fixed(minute: 750)), ("Gym", .part(.evening)),
            ("Renew passport", .anytime),
        ].enumerated() {
            let task = TaskValue(
                title: item.0, type: .oneTime, date: today, createdAt: Date(timeIntervalSince1970: Double(index)))
            data.tasks.append(task)
            data.schedules.append(
                ScheduleValue(
                    taskID: task.id, effectiveFrom: .distantPast, timing: item.1, weekdays: .none,
                    createdAt: task.createdAt))
        }
        let read = TaskValue(
            title: "Read", type: .duration, startDay: today, createdAt: Date(timeIntervalSince1970: 10))
        data.tasks.append(read)
        data.schedules.append(
            ScheduleValue(
                taskID: read.id, effectiveFrom: today, timing: .part(.evening), weekdays: .all, targetMinutes: 30,
                createdAt: read.createdAt))
        return data
    }
}
