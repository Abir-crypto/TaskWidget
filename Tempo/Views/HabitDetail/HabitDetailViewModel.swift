import Core
import Foundation
import Observation

/// State for Habit detail (SPEC F-13).
@Observable
@MainActor
final class HabitDetailViewModel {
    private(set) var task: TaskValue?
    private(set) var schedule: ScheduleValue?
    private(set) var week: [(day: DayKey, result: DayResult)] = []
    private(set) var monthDays: [DayKey: DayResult] = [:]
    /// The first day of the month shown in the calendar.
    private(set) var month: DayKey
    private(set) var stats: [RangeStat] = []
    private(set) var streak: Streak = .zero
    private(set) var todaysEntries: [TimeEntryValue] = []
    /// Yesterday's entries during the correction window; empty after it.
    private(set) var yesterdaysEntries: [TimeEntryValue] = []
    private(set) var recentMissed: [MissedItem] = []
    private(set) var hasData = false
    private(set) var isLoaded = false
    var errorMessage: String?
    var isConfirmingEnd = false
    var restarted = false

    private var snapshot: Snapshot?
    private let tasks: TaskManager
    private let clock: any Clock
    let taskID: UUID

    init(tasks: TaskManager, clock: any Clock, taskID: UUID) {
        self.tasks = tasks
        self.clock = clock
        self.taskID = taskID
        self.month = DayKey(clock.now, calendar: clock.calendar).startOfMonth
    }

    var calendar: Calendar { clock.calendar }
    var today: DayKey { DayKey(clock.now, calendar: calendar) }

    func load() {
        do {
            let snapshot = try tasks.snapshot()
            self.snapshot = snapshot
            guard let task = snapshot.engine.task(id: taskID) else {
                self.task = nil
                isLoaded = true
                return
            }
            self.task = task
            schedule = snapshot.engine.latestSchedule(for: taskID)
            let stats = StatsCalculator(snapshot: snapshot, now: clock.now)
            week = today.week(in: calendar).map { day in
                (day, DayResult(stats.statuses(of: task, from: day, through: day)[day]))
            }
            loadMonth()
            self.stats = StatsRangeKind.allCases.map { rangeStat($0, task: task, stats: stats, snapshot: snapshot) }
            streak = stats.streak(of: task)
            todaysEntries = snapshot.activity.timeEntries.filter { $0.taskID == taskID && $0.day == today }
            // Yesterday's entries, while they can still be deleted (SPEC F-13, §5.11).
            let window = EditWindow(now: clock.now, parts: snapshot.parts, calendar: calendar)
            yesterdaysEntries = snapshot.activity.timeEntries.filter {
                $0.taskID == taskID && $0.day == window.correctableDay
            }
            recentMissed = missedDays(snapshot: snapshot)
            hasData =
                stats.rate(of: task, from: task.startDay ?? today, through: today).counted > 0
                || snapshot.activity.timeEntries.contains { $0.taskID == taskID }
            isLoaded = true
        } catch {
            Log.tasks.error("Couldn't load Habit detail: \(error)")
        }
    }

    private func rangeStat(
        _ kind: StatsRangeKind, task: TaskValue, stats: StatsCalculator, snapshot: Snapshot
    ) -> RangeStat {
        let range = StatsRange.containing(today, kind: kind, calendar: calendar)
        let rate = stats.rate(of: task, from: range.first, through: range.last)
        guard task.type == .duration else { return RangeStat(kind: kind, rate: rate, minutes: nil, weeklyGoal: nil) }
        let math = DurationMath(snapshot: snapshot)
        return RangeStat(
            kind: kind, rate: rate, minutes: math.total(of: task, from: range.first, through: range.last),
            weeklyGoal: kind == .week ? math.goal(of: task, from: range.first, through: range.last) : nil)
    }

    /// Up to 10 missed or short days, newest first, today included.
    private func missedDays(snapshot: Snapshot) -> [MissedItem] {
        let now = clock.now
        let todays = MissedQueries.missedToday(in: snapshot, now: now).filter { $0.occurrence.task.id == taskID }
        let earlier = MissedQueries.missedEarlier(in: snapshot, now: now, filter: MissedFilter(taskID: taskID))
        return Array((todays + earlier).prefix(10))
    }

    // MARK: Header

    var typeTitle: String { task?.type.title ?? "" }

    var scheduleSummary: String {
        guard let task, let schedule else { return "" }
        return ScheduleFormatter.summary(schedule, type: task.type, calendar: calendar)
    }

    var targetText: String? {
        guard task?.type == .duration, let target = schedule?.targetMinutes else { return nil }
        return String(localized: "\(target) min a day")
    }

    /// "Day 12 of 30", "Ongoing", "Starts Thu 8 Oct" or "Ended Sat 26 Sep".
    var lengthText: String {
        guard let task else { return "" }
        if isEnded, let last = task.lastDay(in: calendar) {
            return String(localized: "Ended \(DayTitleFormatter.shortDate(last, calendar: calendar))")
        }
        if HabitProgress.hasNotStarted(task, today: today), let start = task.startDay {
            return String(localized: "Starts \(DayTitleFormatter.shortDate(start, calendar: calendar))")
        }
        if let day = HabitProgress.dayOfLength(of: task, today: today, calendar: calendar) {
            return String(localized: "Day \(day.day) of \(day.length)")
        }
        return String(localized: "Ongoing")
    }

    var isEnded: Bool {
        guard let task else { return false }
        return task.hasEnded(today: today, calendar: calendar)
    }

    var canLogTime: Bool {
        guard let task else { return false }
        // Habit detail logs to today; yesterday's rows on Today and in Missed log to yesterday (SPEC §5.11).
        return Editability.canLogTime(task: task, day: today, in: EditWindow(today: today), calendar: calendar)
    }

    // MARK: Month calendar

    var canShowPreviousMonth: Bool {
        guard let start = task?.startDay else { return false }
        return month > start.startOfMonth
    }

    var canShowNextMonth: Bool {
        month < today.startOfMonth
    }

    func showPreviousMonth() {
        guard canShowPreviousMonth else { return }
        month = month.adding(days: -1, in: calendar).startOfMonth
        loadMonth()
    }

    func showNextMonth() {
        guard canShowNextMonth else { return }
        month = month.adding(days: 31, in: calendar).startOfMonth
        loadMonth()
    }

    private func loadMonth() {
        guard let snapshot, let task else { return }
        let range = StatsRange.containing(month, kind: .month, calendar: calendar)
        let statuses = StatsCalculator(snapshot: snapshot, now: clock.now).statuses(
            of: task, from: range.first, through: range.last)
        monthDays = statuses.mapValues(DayResult.init)
    }

    // MARK: Actions

    func deleteEntry(_ entry: TimeEntryValue) {
        do {
            try tasks.deleteTimeEntry(id: entry.id)
            load()
        } catch {
            errorMessage = TaskEditorViewModel.message(for: error)
        }
    }

    func canDelete(_ entry: TimeEntryValue) -> Bool {
        let parts = (try? tasks.parts()) ?? .defaults
        return Editability.canDeleteTimeEntry(entry, in: EditWindow(now: clock.now, parts: parts, calendar: calendar))
    }

    func endHabit() {
        do {
            try tasks.endHabit(taskID: taskID)
            load()
        } catch {
            errorMessage = TaskEditorViewModel.message(for: error)
        }
    }

    func startAgain() {
        do {
            try tasks.startAgain(taskID: taskID)
            restarted = true
        } catch {
            errorMessage = TaskEditorViewModel.message(for: error)
        }
    }
}
