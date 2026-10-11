import Core
import Foundation

/// Snapshots and timers for widget previews.
extension WidgetSnapshot {
    static func preview(
        timer: TimerState?, habitTitle: String? = nil, data: TaskData = TaskData(), hidesTitles: Bool = false,
        theme: ThemeColor = .default
    ) -> WidgetSnapshot {
        WidgetSnapshot(
            core: Snapshot(
                data: data, settings: SettingsValue(hideLockScreenTitles: hidesTitles, tintColor: theme),
                calendar: .autoupdatingCurrent),
            timer: timer, timerHabitTitle: habitTitle)
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
        preview([
            ("Call the bank", .oneTime, .part(.noon)), ("Interview", .oneTime, .fixed(minute: 750)),
            ("Gym", .oneTime, .part(.evening)), ("Renew passport", .oneTime, .anytime),
            ("Read", .duration, .part(.evening)),
        ])
    }

    /// A duration habit in the evening, for the Lock Screen's progress line.
    static var durationPreview: TaskData { preview([("Read", .duration, .part(.evening))]) }

    /// A single Anytime task.
    static var anytimePreview: TaskData { preview([("Renew passport", .oneTime, .anytime)]) }

    /// Two of today's tasks, both done.
    static var allDonePreview: TaskData {
        var data = preview([("Call the bank", .oneTime, .part(.noon)), ("Gym", .oneTime, .part(.morning))])
        let today = DayKey(.now, calendar: .autoupdatingCurrent)
        data.completions = data.tasks.map { CompletionValue(taskID: $0.id, day: today, createdAt: .now) }
        return data
    }

    /// Today's tasks in creation order. Habits run every day from today; duration habits aim for 30 minutes.
    private static func preview(_ items: [(title: String, type: TaskType, timing: Timing)]) -> TaskData {
        let today = DayKey(.now, calendar: .autoupdatingCurrent)
        var data = TaskData()
        for (index, item) in items.enumerated() {
            let createdAt = Date(timeIntervalSince1970: Double(index))
            let isHabit = item.type != .oneTime
            let task = TaskValue(
                title: item.title, type: item.type, date: isHabit ? nil : today, startDay: isHabit ? today : nil,
                createdAt: createdAt)
            data.tasks.append(task)
            data.schedules.append(
                ScheduleValue(
                    taskID: task.id, effectiveFrom: isHabit ? today : .distantPast, timing: item.timing,
                    weekdays: isHabit ? .all : .none, targetMinutes: item.type == .duration ? 30 : nil,
                    createdAt: createdAt))
        }
        return data
    }
}

extension Date {
    /// Today at a time of day, for previews of a particular moment.
    static func previewToday(_ hour: Int, _ minute: Int = 0) -> Date {
        Calendar.autoupdatingCurrent.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
    }
}
