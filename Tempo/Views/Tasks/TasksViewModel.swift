import Core
import Foundation
import Observation

/// State for the Tasks tab (SPEC F-11): active habits with their progress, and upcoming one-time tasks.
@Observable
@MainActor
final class TasksViewModel {
    private(set) var habits: [HabitSummary] = []
    private(set) var oneTimeGroups: [OneTimeGroup] = []
    private(set) var isLoaded = false

    private let tasks: TaskManager
    private let clock: any Clock

    init(tasks: TaskManager, clock: any Clock) {
        self.tasks = tasks
        self.clock = clock
    }

    func load() {
        do {
            let snapshot = try tasks.snapshot()
            let now = clock.now
            let calendar = clock.calendar
            let today = DayKey(now, calendar: calendar)
            habits = snapshot.engine.tasks
                .filter { $0.type.isHabit && !$0.hasEnded(today: today, calendar: calendar) }
                .compactMap { summary(for: $0, snapshot: snapshot, today: today) }
            oneTimeGroups = upcomingOneTime(snapshot: snapshot, now: now, today: today)
            isLoaded = true
        } catch {
            Log.tasks.error("Couldn't load Tasks: \(error)")
        }
    }

    private func summary(for task: TaskValue, snapshot: Snapshot, today: DayKey) -> HabitSummary? {
        guard let schedule = snapshot.engine.latestSchedule(for: task.id) else { return nil }
        let calendar = snapshot.calendar
        let progress: String
        if HabitProgress.hasNotStarted(task, today: today), let start = task.startDay {
            progress = String(localized: "Starts \(DayTitleFormatter.shortDate(start, calendar: calendar))")
        } else if task.type == .duration {
            let week = DurationMath(snapshot: snapshot).weeklyProgress(of: task, containing: today)
            progress = String(
                localized:
                    "\(DurationFormatter.short(minutes: week.minutes)) of \(DurationFormatter.short(minutes: week.goal)) this week"
            )
        } else if let day = HabitProgress.dayOfLength(of: task, today: today, calendar: calendar) {
            progress = String(localized: "Day \(day.day) of \(day.length)")
        } else {
            let week = HabitProgress.week(of: task, snapshot: snapshot, today: today)
            progress = String(localized: "\(week.done) of \(week.scheduled) this week")
        }
        return HabitSummary(
            task: task, schedule: ScheduleFormatter.summary(schedule, type: task.type, calendar: calendar),
            progress: progress)
    }

    /// One-time tasks dated today or later that aren't done; today's missed ones live in the Missed tab.
    private func upcomingOneTime(snapshot: Snapshot, now: Date, today: DayKey) -> [OneTimeGroup] {
        let calendar = snapshot.calendar
        let occurrences = snapshot.engine.tasks.compactMap { task -> Occurrence? in
            guard task.type == .oneTime, let date = task.date, date >= today else { return nil }
            return snapshot.engine.occurrence(of: task, on: date)
        }
        let items = occurrences.map {
            DayItem(occurrence: $0, status: snapshot.status(of: $0, now: now), minutes: 0, targetMinutes: nil)
        }
        .filter { $0.status.isPending }
        let byDay = Dictionary(grouping: items, by: \.occurrence.day)
        return byDay.keys.sorted().map { day in
            let ordered = DayOrder.sorted(byDay[day]?.map(\.occurrence) ?? [], parts: snapshot.parts)
            let lookup = Dictionary(uniqueKeysWithValues: (byDay[day] ?? []).map { ($0.id, $0) })
            return OneTimeGroup(
                day: day, title: DayTitleFormatter.title(for: day, today: today, calendar: calendar),
                items: ordered.compactMap { lookup[$0.id] })
        }
    }
}
