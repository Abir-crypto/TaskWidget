import Core
import Foundation
import Observation

/// State for the Today screen (SPEC F-10): the selected day, its plan, and the actions F-04 allows.
@Observable
@MainActor
final class TodayViewModel {
    /// The day shown. Starts on today.
    private(set) var selectedDay: DayKey
    /// Ended parts of today that the user has expanded.
    private(set) var expandedEndedParts: Set<DayPart> = []
    /// A section or row a link asked for (`DaySection.id` or `DayItem.id`); the view scrolls to it.
    var scrollTarget: String?
    /// A delete waiting for confirmation.
    var pendingDelete: DayItem?
    var errorMessage: String?

    private(set) var snapshot: Snapshot?
    private let tasks: TaskManager
    private let clock: any Clock

    init(tasks: TaskManager, clock: any Clock) {
        self.tasks = tasks
        self.clock = clock
        self.selectedDay = DayKey(clock.now, calendar: clock.calendar)
    }

    var calendar: Calendar { clock.calendar }
    var now: Date { clock.now }
    var today: DayKey { DayKey(clock.now, calendar: calendar) }
    var isShowingToday: Bool { selectedDay == today }
    var isPastDay: Bool { selectedDay < today }

    /// Reads the data fresh from storage.
    func load() {
        do {
            snapshot = try tasks.snapshot()
        } catch {
            Log.tasks.error("Couldn't load Today: \(error)")
        }
    }

    // MARK: What's shown

    /// The selected day's plan as of `now`.
    func plan(at now: Date) -> DayPlan? {
        snapshot.map { DayPlan(day: selectedDay, snapshot: $0, now: now) }
    }

    /// "Today", "Tomorrow", "Yesterday" or "Thu 8 Oct".
    var title: String {
        DayTitleFormatter.title(for: selectedDay, today: today, calendar: calendar)
    }

    /// The seven days of the selected day's week, each with its dot.
    func week(at now: Date) -> [DayStripDay] {
        let today = DayKey(now, calendar: calendar)
        return selectedDay.week(in: calendar).map { day in
            guard let snapshot else { return DayStripDay(day: day, dot: .none, isToday: day == today) }
            let occurrences = snapshot.occurrences(on: day)
            let dot: DayStripDay.Dot
            if occurrences.isEmpty {
                dot = .none
            } else if day <= today, occurrences.contains(where: { snapshot.status(of: $0, now: now).countsAsMissed }) {
                dot = .missed
            } else {
                dot = .tasks
            }
            return DayStripDay(day: day, dot: dot, isToday: day == today)
        }
    }

    /// Whether an ended part of today shows as one collapsed line.
    func isCollapsed(_ section: DaySection) -> Bool {
        guard section.phase == .ended, let part = section.part, !section.items.isEmpty else { return false }
        return !expandedEndedParts.contains(part)
    }

    func toggleExpanded(_ part: DayPart) {
        if expandedEndedParts.contains(part) {
            expandedEndedParts.remove(part)
        } else {
            expandedEndedParts.insert(part)
        }
    }

    // MARK: Choosing a day

    func select(_ day: DayKey) {
        guard day != selectedDay else { return }
        selectedDay = day
        expandedEndedParts = []
    }

    func goToToday() {
        select(today)
    }

    /// Swiping the day strip moves by a week.
    func moveWeek(by weeks: Int) {
        select(selectedDay.adding(days: 7 * weeks, in: calendar))
    }

    /// Opens a day, part or task that a link asked for (SPEC F-09).
    func focus(_ focus: TodayFocus) {
        select(focus.day ?? today)
        if let taskID = focus.taskID {
            scrollTarget = Occurrence.id(taskID: taskID, day: selectedDay)
            if let part = plan(at: now)?.items.first(where: { $0.task.id == taskID })?.occurrence.part(parts: parts) {
                expandedEndedParts.insert(part)
            }
        } else if let part = focus.part {
            expandedEndedParts.insert(part)
            scrollTarget = part.rawValue
        }
    }

    private var parts: PartSettings { snapshot?.parts ?? .defaults }

    // MARK: What F-04 allows

    func canComplete(_ item: DayItem) -> Bool {
        Editability.canComplete(item.occurrence, today: today)
    }

    func canLogTime(_ item: DayItem) -> Bool {
        Editability.canLogTime(task: item.task, day: item.occurrence.day, today: today, calendar: calendar)
    }

    func canMove(_ item: DayItem) -> Bool {
        guard Editability.canMove(item.occurrence, status: item.status, today: today) else { return false }
        guard item.status == .missed, let snapshot else { return true }
        return !tasks.hasCopyTomorrow(item.occurrence, in: snapshot)
    }

    /// Edit and Delete are offered from today on. Past days are read-only.
    func canEditOrDelete(_ item: DayItem) -> Bool {
        item.occurrence.day >= today
    }

    // MARK: Actions

    func toggleCompletion(_ item: DayItem) {
        perform { try tasks.toggleCompletion(taskID: item.task.id, day: item.occurrence.day) }
    }

    func moveToNextDay(_ item: DayItem) {
        perform { try tasks.moveToNextDay(taskID: item.task.id) }
    }

    func requestDelete(_ item: DayItem) {
        pendingDelete = item
    }

    func deleteOneTime(_ item: DayItem) {
        perform { try tasks.deleteOneTime(taskID: item.task.id) }
    }

    func endHabit(_ item: DayItem) {
        perform { try tasks.endHabit(taskID: item.task.id) }
    }

    func deleteWithHistory(_ item: DayItem) {
        perform { try tasks.deleteWithHistory(taskID: item.task.id) }
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
            load()
        } catch {
            errorMessage = TaskEditorViewModel.message(for: error)
            load()
        }
    }
}
