import Core
import Foundation
import Observation

/// State for the task editor (SPEC F-15): a new task with presets, or an existing task.
@Observable
@MainActor
final class TaskEditorViewModel {
    // MARK: Fields

    var type: TaskType = .oneTime
    var title = "" {
        didSet { titleEdited = true }
    }
    /// Optional notes, several lines (SPEC F-15).
    var notes = ""
    var timingKind: TimingKind = .part
    var fixedMinute = 540
    var part: DayPart = .morning
    /// One-time tasks: the date.
    var date: DayKey
    /// Habits: the weekdays, all on by default.
    var weekdays: Weekdays = .all
    /// Habits: the start day.
    var startDay: DayKey
    var hasLength = false
    var lengthDays = TaskRules.defaultLength
    var targetMinutes = TaskRules.defaultTarget

    // MARK: State

    /// The task being edited, or `nil` for a new task.
    private(set) var editing: TaskValue?
    /// Shown in an alert when saving or deleting fails.
    var errorMessage: String?
    /// The title message appears once the title has been edited, not on a fresh editor (D-068).
    private(set) var titleEdited = false

    private let tasks: TaskManager
    private let clock: any Clock
    private var parts: PartSettings = .defaults
    /// The schedule the task had when the editor opened.
    private var originalTiming: Timing?

    init(tasks: TaskManager, clock: any Clock, request: EditorRequest) {
        self.tasks = tasks
        self.clock = clock
        let today = DayKey(clock.now, calendar: clock.calendar)
        date = today
        startDay = today
        if case .new(let day, let presetType) = request.mode {
            let day = max(day ?? today, today)
            date = day
            startDay = day
            type = presetType ?? .oneTime
        }
        pendingEditID = if case .edit(let id) = request.mode { id } else { nil }
    }

    private var pendingEditID: UUID?

    /// Loads the part times and, when editing, the task. Call once from `.task`.
    func load() {
        do {
            parts = try tasks.parts()
            if let id = pendingEditID {
                pendingEditID = nil
                try loadTask(id)
            } else if editing == nil {
                chooseDefaultTiming()
            }
        } catch {
            errorMessage = String(localized: "This task couldn't be loaded.")
        }
    }

    private func loadTask(_ id: UUID) throws {
        let engine = try tasks.engine()
        guard let task = engine.task(id: id), let schedule = engine.latestSchedule(for: id) else {
            errorMessage = String(localized: "This task no longer exists.")
            return
        }
        editing = task
        type = task.type
        title = task.title
        titleEdited = false
        notes = task.notes ?? ""
        apply(schedule.timing)
        originalTiming = schedule.timing
        date = task.date ?? date
        startDay = task.startDay ?? startDay
        weekdays = task.type.isHabit ? schedule.weekdays : .all
        hasLength = task.lengthDays != nil
        lengthDays = task.lengthDays ?? TaskRules.defaultLength
        targetMinutes = schedule.targetMinutes ?? TaskRules.defaultTarget
    }

    private func apply(_ timing: Timing) {
        timingKind = timing.kind
        if case .fixed(let minute) = timing { fixedMinute = minute }
        if case .part(let value) = timing { part = value }
    }

    /// A new task starts in the part in progress (or Morning on other days), at the next 5-minute step (D-068).
    private func chooseDefaultTiming() {
        let now = LocalTime(clock.now, calendar: clock.calendar)
        if day == now.day {
            part = NextTaskRule.currentPart(at: now.minute, parts: parts) ?? .morning
            let next = (now.minute + Timing.fixedStep) / Timing.fixedStep * Timing.fixedStep
            fixedMinute = min(max(next, fixedMinuteRange.lowerBound), fixedMinuteRange.upperBound)
        } else {
            part = .morning
            fixedMinute = 540
        }
    }

    // MARK: Derived

    var isEditing: Bool { editing != nil }
    var today: DayKey { DayKey(clock.now, calendar: clock.calendar) }
    var calendar: Calendar { clock.calendar }

    /// The day the task (or its next change) applies to: the date for one-time tasks; for habits, the start day,
    /// or today once the habit has started.
    var day: DayKey {
        if type == .oneTime { return date }
        return max(startDay, today)
    }

    var timing: Timing {
        switch timingKind {
        case .fixed: .fixed(minute: fixedMinute)
        case .part: .part(part)
        case .anytime: .anytime
        }
    }

    /// Past one-time tasks are shown read-only (SPEC F-04).
    var isReadOnly: Bool {
        guard let editing else { return false }
        return editing.type == .oneTime && !Editability.canEditOneTime(editing, today: today)
    }

    /// Timing, weekdays, target and length change only while the habit hasn't ended (SPEC F-04).
    var canEditSchedule: Bool {
        guard let editing else { return true }
        if editing.type == .oneTime { return !isReadOnly }
        return Editability.canEditHabitSchedule(editing, today: today, calendar: calendar)
    }

    /// The start day can only change while it's still in the future (SPEC F-03).
    var canEditStartDay: Bool {
        guard let editing else { return true }
        return (editing.startDay ?? today) > today
    }

    var showsScheduleNote: Bool { isEditing && type.isHabit && canEditSchedule }

    /// Whether a part has already ended on the editor's day, which makes it unavailable (SPEC F-15).
    func isOver(_ part: DayPart) -> Bool {
        TaskRules.isOver(.part(part), on: day, now: LocalTime(clock.now, calendar: calendar), parts: parts)
    }

    /// Fixed times can't be inside a part that has ended today.
    var fixedMinuteRange: ClosedRange<Int> {
        let earliest = TaskRules.earliestFixedMinute(
            on: day, now: LocalTime(clock.now, calendar: calendar), parts: parts)
        return earliest...(DayKey.minutesPerDay - Timing.fixedStep)
    }

    /// "Add a title", once the title has been edited and is empty.
    var titleMessage: String? {
        guard titleEdited, TaskRules.titleError(title) == .emptyTitle else { return nil }
        return String(localized: "Add a title")
    }

    /// Shown once the notes are longer than 1,000 characters (SPEC §7).
    var notesMessage: String? {
        guard TaskRules.notesError(notes) == .notesTooLong else { return nil }
        return String(localized: "Notes can be up to 1,000 characters.")
    }

    var weekdaysMessage: String? {
        guard type.isHabit, weekdays.isEmpty else { return nil }
        return String(localized: "Pick at least one day")
    }

    /// The first thing keeping Save disabled, if any.
    var validationError: TaskRuleError? {
        if let error = TaskRules.titleError(title) ?? TaskRules.notesError(notes) { return error }
        if type.isHabit, weekdays.isEmpty { return .noWeekdays }
        guard !isReadOnly else { return nil }
        if type == .oneTime, date < today { return .dayInPast }
        if type.isHabit, canEditStartDay, startDay < today { return .dayInPast }
        // A timing the task already had is kept even if its part has ended; a new one can't be over.
        if timing != originalTiming || !isEditing,
            TaskRules.isOver(timing, on: day, now: LocalTime(clock.now, calendar: calendar), parts: parts)
        {
            return .partAlreadyOver
        }
        return nil
    }

    var canSave: Bool { !isReadOnly && validationError == nil }

    // MARK: Actions

    /// Saves the task. Returns `true` when the editor can close.
    @discardableResult
    func save() -> Bool {
        guard canSave else { return false }
        let target = type == .duration ? targetMinutes : nil
        let length = hasLength ? lengthDays : nil
        do {
            if let editing {
                switch editing.type {
                case .oneTime:
                    try tasks.updateOneTime(taskID: editing.id, title: title, date: date, timing: timing)
                    try tasks.setNotes(taskID: editing.id, notes: notes)
                case .progress, .duration:
                    try tasks.rename(taskID: editing.id, to: title)
                    try tasks.setNotes(taskID: editing.id, notes: notes)
                    if canEditStartDay, startDay != editing.startDay {
                        try tasks.setStartDay(taskID: editing.id, to: startDay)
                    }
                    if canEditSchedule {
                        try tasks.updateSchedule(
                            taskID: editing.id, timing: timing, weekdays: weekdays, targetMinutes: target)
                        if length != editing.lengthDays {
                            try tasks.setLength(taskID: editing.id, lengthDays: length)
                        }
                    }
                }
            } else if type == .oneTime {
                try tasks.createOneTime(title: title, notes: notes, date: date, timing: timing)
            } else {
                try tasks.createHabit(
                    type: type, title: title, notes: notes, timing: timing, weekdays: weekdays, startDay: startDay,
                    lengthDays: length, targetMinutes: target)
            }
            return true
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    /// Deletes a one-time task, ends a habit, or deletes a habit with its history. Returns `true` on success.
    @discardableResult
    func perform(_ action: DestructiveAction) -> Bool {
        guard let editing else { return false }
        do {
            switch action {
            case .deleteOneTime: try tasks.deleteOneTime(taskID: editing.id)
            case .endHabit: try tasks.endHabit(taskID: editing.id)
            case .deleteWithHistory: try tasks.deleteWithHistory(taskID: editing.id)
            }
            return true
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    enum DestructiveAction {
        case deleteOneTime
        case endHabit
        case deleteWithHistory
    }

    static func message(for error: any Error) -> String {
        switch error as? TaskError {
        case .invalid(.partAlreadyOver):
            String(localized: "That part of the day is already over. Pick a later time.")
        case .invalid(.dayInPast):
            String(localized: "Pick today or a later day.")
        case .invalid:
            String(localized: "Check the highlighted fields.")
        case .notFound:
            String(localized: "This task no longer exists.")
        case .notAllowed, .wrongType:
            String(localized: "This task can't be changed any more.")
        case nil:
            String(localized: "Something went wrong. Try again.")
        }
    }
}
