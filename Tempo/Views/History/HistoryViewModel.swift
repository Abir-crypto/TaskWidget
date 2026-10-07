import Core
import Foundation
import Observation

/// State for History (SPEC F-12): completed one-time tasks and ended habits, filtered by a search.
@Observable
@MainActor
final class HistoryViewModel {
    var segment: HistorySegment = .oneTime
    var searchText = ""
    var errorMessage: String?
    /// Set after Start again, for a short confirmation.
    var restartedTitle: String?
    private(set) var isLoaded = false

    private var allCompleted: [CompletedGroup] = []
    private var allEnded: [EndedHabit] = []
    private let tasks: TaskManager
    private let clock: any Clock

    init(tasks: TaskManager, clock: any Clock) {
        self.tasks = tasks
        self.clock = clock
    }

    func load() {
        do {
            let snapshot = try tasks.snapshot()
            let calendar = clock.calendar
            let today = DayKey(clock.now, calendar: calendar)
            allCompleted = completedGroups(snapshot: snapshot, today: today)
            allEnded = endedHabits(snapshot: snapshot, today: today)
            isLoaded = true
        } catch {
            Log.tasks.error("Couldn't load History: \(error)")
        }
    }

    // MARK: Filtered lists

    var completedGroups: [CompletedGroup] {
        guard isSearching else { return allCompleted }
        return allCompleted.compactMap { group in
            let tasks = group.tasks.filter { matches($0.task.title) }
            return tasks.isEmpty ? nil : CompletedGroup(day: group.day, title: group.title, tasks: tasks)
        }
    }

    var endedHabits: [EndedHabit] {
        guard isSearching else { return allEnded }
        return allEnded.filter { matches($0.task.title) }
    }

    var isSearching: Bool { !searchText.trimmingCharacters(in: .whitespaces).isEmpty }

    /// Whether the current segment has nothing to show before searching.
    var segmentIsEmpty: Bool {
        segment == .oneTime ? allCompleted.isEmpty : allEnded.isEmpty
    }

    private func matches(_ title: String) -> Bool {
        title.localizedStandardContains(searchText.trimmingCharacters(in: .whitespaces))
    }

    // MARK: Building

    /// Completed one-time tasks, grouped by the day they were completed, newest first.
    private func completedGroups(snapshot: Snapshot, today: DayKey) -> [CompletedGroup] {
        let calendar = snapshot.calendar
        let completions = Dictionary(grouping: snapshot.activity.completions, by: \.taskID)
        let completed: [CompletedTask] = snapshot.engine.tasks.compactMap { task in
            guard task.type == .oneTime, let date = task.date,
                let completion = completions[task.id]?.filter({ $0.day == date }).min(by: {
                    $0.createdAt < $1.createdAt
                })
            else { return nil }
            let completedOn = DayKey(completion.createdAt, calendar: calendar)
            return CompletedTask(
                task: task, completedOn: completedOn, completedAt: completion.createdAt,
                canUndo: completedOn == today && date >= today)
        }
        let byDay = Dictionary(grouping: completed, by: \.completedOn)
        return byDay.keys.sorted(by: >).map { day in
            CompletedGroup(
                day: day, title: DayTitleFormatter.title(for: day, today: today, calendar: calendar),
                tasks: (byDay[day] ?? []).sorted { $0.completedAt > $1.completedAt })
        }
    }

    /// Habits whose last day is before today, most recently ended first.
    private func endedHabits(snapshot: Snapshot, today: DayKey) -> [EndedHabit] {
        let calendar = snapshot.calendar
        let stats = StatsCalculator(snapshot: snapshot, now: clock.now)
        let math = DurationMath(snapshot: snapshot)
        let ended = snapshot.engine.tasks.filter { $0.type.isHabit && $0.hasEnded(today: today, calendar: calendar) }
        return
            ended
            .sorted { ($0.lastDay(in: calendar) ?? today) > ($1.lastDay(in: calendar) ?? today) }
            .compactMap { task in
                guard let start = task.startDay, let last = task.lastDay(in: calendar) else { return nil }
                let rate = stats.rate(of: task, from: start, through: last)
                let result: String
                if task.type == .duration {
                    let total = DurationFormatter.short(minutes: math.total(of: task, from: start, through: last))
                    result = String(localized: "On target \(rate.done) of \(rate.counted) days · \(total) total")
                } else {
                    result = String(localized: "Done \(rate.done) of \(rate.counted) days")
                }
                return EndedHabit(
                    task: task, result: result,
                    ended: String(localized: "Ended \(DayTitleFormatter.shortDate(last, calendar: calendar))"))
            }
    }

    // MARK: Actions

    func markNotDone(_ item: CompletedTask) {
        guard item.canUndo, let date = item.task.date else { return }
        do {
            try tasks.undoCompletion(taskID: item.task.id, day: date)
            load()
        } catch {
            errorMessage = TaskEditorViewModel.message(for: error)
        }
    }

    func startAgain(_ habit: EndedHabit) {
        do {
            try tasks.startAgain(taskID: habit.task.id)
            restartedTitle = habit.task.title
            load()
        } catch {
            errorMessage = TaskEditorViewModel.message(for: error)
        }
    }
}
