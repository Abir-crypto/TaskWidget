import Core
import Foundation
import Observation

/// State for the Missed tab (SPEC F-08): today's missed tasks, which can still change, and earlier ones,
/// read-only with sort and filters. Filters live only while the app runs.
@Observable
@MainActor
final class MissedViewModel {
    var filter = MissedFilter.default {
        didSet { if filter != oldValue { applyFilter() } }
    }
    private(set) var todayItems: [MissedItem] = []
    /// Yesterday's Missed and Short tasks while it can still be corrected (SPEC F-08, §5.11); empty after the window.
    private(set) var yesterdayItems: [MissedItem] = []
    private(set) var earlierGroups: [MissedGroup] = []
    /// How many earlier items match the filters ("14 missed").
    private(set) var earlierCount = 0
    /// Whether anything was missed before today at all, before filtering.
    private(set) var hasEarlier = false
    /// Tasks offered by the "specific task" filter: every live task, by title.
    private(set) var filterableTasks: [TaskValue] = []
    /// Occurrence ids the missed popup asked to highlight (T-17).
    var highlighted: Set<String> = []
    var errorMessage: String?
    /// Counts completions made here, so the screen can give haptic feedback for each (SPEC T-31).
    private(set) var completions = 0
    private(set) var isLoaded = false

    private var snapshot: Snapshot?
    /// The correction window as of the last load; Earlier leaves out yesterday while it's open.
    private var window: EditWindow?
    private let tasks: TaskManager
    private let clock: any Clock

    init(tasks: TaskManager, clock: any Clock) {
        self.tasks = tasks
        self.clock = clock
    }

    var calendar: Calendar { clock.calendar }
    var today: DayKey { DayKey(clock.now, calendar: calendar) }

    func load() {
        do {
            let snapshot = try tasks.snapshot()
            self.snapshot = snapshot
            let window = EditWindow(now: clock.now, parts: snapshot.parts, calendar: calendar)
            self.window = window
            todayItems = MissedQueries.missedToday(in: snapshot, now: clock.now)
            yesterdayItems = MissedQueries.missedCorrectable(in: snapshot, now: clock.now, window: window)
            hasEarlier = !MissedQueries.missedEarlier(
                in: snapshot, now: clock.now, filter: .default, window: window
            ).isEmpty
            filterableTasks = snapshot.engine.tasks.sorted {
                $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
            applyFilter()
            isLoaded = true
        } catch {
            Log.tasks.error("Couldn't load Missed: \(error)")
        }
    }

    private func applyFilter() {
        guard let snapshot else { return }
        let items = MissedQueries.missedEarlier(in: snapshot, now: clock.now, filter: filter, window: window)
        earlierCount = items.count
        var groups: [MissedGroup] = []
        for item in items {
            if groups.last?.day == item.day {
                let last = groups.removeLast()
                groups.append(MissedGroup(day: last.day, title: last.title, items: last.items + [item]))
            } else {
                groups.append(
                    MissedGroup(
                        day: item.day, title: DayTitleFormatter.shortDate(item.day, calendar: calendar), items: [item]))
            }
        }
        earlierGroups = groups
    }

    /// Filters Earlier to one task, as Habit detail's "See all" asks (SPEC F-13).
    func showOnly(taskID: UUID) {
        filter = MissedFilter(sort: filter.sort, taskID: taskID)
    }

    func clearFilters() {
        filter = filter.cleared
    }

    // MARK: Rows

    /// "Tue 29 Sep · Noon", "Tue 29 Sep · 12:30" or "Tue 29 Sep · Anytime".
    func dueText(_ item: MissedItem) -> String {
        "\(DayTitleFormatter.shortDate(item.day, calendar: calendar)) · \(ScheduleFormatter.timing(item.occurrence.timing))"
    }

    private var currentWindow: EditWindow {
        EditWindow(now: clock.now, parts: snapshot?.parts ?? .defaults, calendar: calendar)
    }

    /// Whether the correction window's state differs from the last load, so the screen reloads when it closes.
    var needsReload: Bool { currentWindow.correctableDay != window?.correctableDay }

    func canMarkDone(_ item: MissedItem) -> Bool {
        Editability.canComplete(item.occurrence, in: currentWindow)
    }

    func canLogTime(_ item: MissedItem) -> Bool {
        Editability.canLogTime(task: item.occurrence.task, day: item.day, in: currentWindow, calendar: calendar)
    }

    func canMove(_ item: MissedItem) -> Bool {
        guard Editability.canMove(item.occurrence, status: item.status, today: today) else { return false }
        guard let snapshot else { return true }
        return !tasks.hasCopyTomorrow(item.occurrence, in: snapshot)
    }

    // MARK: Actions on today's items

    func markDone(_ item: MissedItem) {
        if perform({ try tasks.complete(taskID: item.occurrence.task.id, day: item.day) }) {
            completions += 1
        }
    }

    func moveToTomorrow(_ item: MissedItem) {
        perform { try tasks.moveToNextDay(taskID: item.occurrence.task.id) }
    }

    /// Runs a change and reloads. Returns whether the change was made.
    @discardableResult
    private func perform(_ action: () throws -> Void) -> Bool {
        defer { load() }
        do {
            try action()
            return true
        } catch {
            errorMessage = TaskEditorViewModel.message(for: error)
            return false
        }
    }
}
