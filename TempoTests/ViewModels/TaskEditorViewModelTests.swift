import Core
import Foundation
import Testing

@testable import Tempo

@MainActor
struct TaskEditorViewModelTests {
    private let clock = TestEnvironment.clock(hour: 10, minute: 30)
    private let store: SwiftDataTaskStore
    private let tasks: TaskManager

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        tasks = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
    }

    private func day(_ day: Int) -> DayKey { DayKey(year: 2026, month: 10, day: day) }

    private func editor(_ request: EditorRequest = .new()) -> TaskEditorViewModel {
        let model = TaskEditorViewModel(tasks: tasks, clock: clock, request: request)
        model.load()
        return model
    }

    // MARK: Creating

    @Test(arguments: TaskType.allCases)
    func eachTypeCanBeCreatedWithEachTiming(type: TaskType) throws {
        for (index, kind) in TimingKind.allCases.enumerated() {
            let model = editor(.new(type: type))
            model.title = "Task \(index)"
            model.timingKind = kind
            model.fixedMinute = 1080
            model.part = .evening
            #expect(model.canSave, "\(type) with \(kind)")
            #expect(model.save())
        }
        let created = try store.tasks()
        #expect(created.count == 3)
        #expect(created.allSatisfy { $0.type == type })
        let timings = try store.schedules(taskID: nil).map(\.timing)
        #expect(Set(timings) == [.fixed(minute: 1080), .part(.evening), .anytime])
    }

    @Test func presetsComeFromTheRequest() {
        let model = editor(.new(day: day(8), type: .duration))
        #expect(model.type == .duration)
        #expect(model.date == day(8))
        #expect(model.startDay == day(8))
        #expect(editor().type == .oneTime)
        #expect(editor().date == day(6))
    }

    @Test func newTasksStartInTheCurrentPart() {
        let model = editor()
        #expect(model.timingKind == .part)
        #expect(model.part == .morning)
        #expect(model.fixedMinute == 635)  // the next 5-minute step after 10:30
        let tomorrow = editor(.new(day: day(7)))
        #expect(tomorrow.part == .morning)
    }

    @Test func habitDefaults() {
        let model = editor(.new(type: .duration))
        #expect(model.weekdays == .all)
        #expect(model.startDay == day(6))
        #expect(!model.hasLength)
        #expect(model.lengthDays == 30)
        #expect(model.targetMinutes == 30)
    }

    // MARK: Validation

    @Test func titleIsRequiredAndItsMessageWaitsForAnEdit() {
        let model = editor()
        #expect(!model.canSave)
        #expect(model.titleMessage == nil)
        model.title = "R"
        #expect(model.canSave)
        model.title = "   "
        #expect(!model.canSave)
        #expect(model.titleMessage == "Add a title")
    }

    @Test func habitsNeedAWeekday() {
        let model = editor(.new(type: .progress))
        model.title = "Gym"
        model.weekdays = .none
        #expect(!model.canSave)
        #expect(model.weekdaysMessage == "Pick at least one day")
        model.weekdays = [.monday]
        #expect(model.canSave)
        #expect(model.weekdaysMessage == nil)
    }

    @Test func pastDaysCantBeChosen() {
        let oneTime = editor()
        oneTime.title = "Late"
        oneTime.date = day(5)
        #expect(oneTime.validationError == .dayInPast)
        let habit = editor(.new(type: .progress))
        habit.title = "Late"
        habit.startDay = day(5)
        #expect(habit.validationError == .dayInPast)
    }

    @Test func endedPartsAreOverToday() {
        clock.now = TestEnvironment.date(2026, 10, 6, 13, 0)
        let model = editor()
        model.title = "Call"
        #expect(model.isOver(.morning))
        #expect(!model.isOver(.noon))
        #expect(model.part == .noon)
        model.part = .morning
        #expect(model.validationError == .partAlreadyOver)
        #expect(!model.canSave)
        #expect(model.fixedMinuteRange.lowerBound == 720)
        // Tomorrow, every part is available.
        model.date = day(7)
        #expect(!model.isOver(.morning))
        #expect(model.canSave)
        #expect(model.fixedMinuteRange.lowerBound == 0)
    }

    @Test func endedFixedTimesAreOverToday() {
        clock.now = TestEnvironment.date(2026, 10, 6, 13, 0)
        let model = editor()
        model.title = "Call"
        model.timingKind = .fixed
        model.fixedMinute = 600
        #expect(model.validationError == .partAlreadyOver)
        model.fixedMinute = 750  // 12:30: passed, but Noon is still open
        #expect(model.canSave)
    }

    // MARK: Editing

    @Test func typeIsFixedWhenEditing() throws {
        let task = try tasks.createOneTime(title: "Call", date: day(6), timing: .anytime)
        let model = editor(.edit(task.id))
        #expect(model.isEditing)
        #expect(model.type == .oneTime)
        #expect(model.title == "Call")
        #expect(model.titleMessage == nil)
        #expect(model.timingKind == .anytime)
    }

    @Test func editingAOneTimeTaskSavesEveryField() throws {
        let task = try tasks.createOneTime(title: "Call", date: day(6), timing: .anytime)
        let model = editor(.edit(task.id))
        model.title = "Call the bank"
        model.date = day(9)
        model.timingKind = .fixed
        model.fixedMinute = 750
        #expect(model.save())
        let saved = try #require(try store.task(id: task.id))
        #expect(saved.title == "Call the bank")
        #expect(saved.date == day(9))
        #expect(try store.schedules(taskID: task.id).map(\.timing) == [.fixed(minute: 750)])
    }

    @Test func missedTaskKeepsItsEndedTimingWhenRenamed() throws {
        let task = try tasks.createOneTime(title: "Call", date: day(6), timing: .part(.morning))
        clock.now = TestEnvironment.date(2026, 10, 6, 13, 0)
        let model = editor(.edit(task.id))
        model.title = "Call the bank"
        #expect(model.canSave)
        #expect(model.save())
        #expect(try store.task(id: task.id)?.title == "Call the bank")
    }

    @Test func editingAHabitWritesScheduleRowsAndShowsTheNote() throws {
        clock.now = TestEnvironment.date(2026, 10, 1, 9)
        let habit = try tasks.createHabit(
            type: .duration, title: "Read", timing: .part(.evening), weekdays: .all, startDay: day(1), lengthDays: nil,
            targetMinutes: 30)
        clock.now = TestEnvironment.date(2026, 10, 6, 10)
        let model = editor(.edit(habit.id))
        #expect(model.showsScheduleNote)
        #expect(!model.canEditStartDay)
        model.targetMinutes = 45
        model.weekdays = [.monday, .wednesday]
        #expect(model.save())
        let rows = try store.schedules(taskID: habit.id)
        #expect(rows.map(\.effectiveFrom) == [day(1), day(6)])
        #expect(rows.last?.targetMinutes == 45)
        #expect(rows.last?.weekdays == [.monday, .wednesday])
        #expect(rows.first?.targetMinutes == 30)
    }

    @Test func editingAFutureHabitMovesItsStartAndFirstRow() throws {
        let habit = try tasks.createHabit(
            type: .progress, title: "Gym", timing: .part(.evening), weekdays: .all, startDay: day(10), lengthDays: nil,
            targetMinutes: nil)
        let model = editor(.edit(habit.id))
        #expect(model.canEditStartDay)
        model.startDay = day(12)
        model.part = .noon
        model.hasLength = true
        model.lengthDays = 14
        #expect(model.save())
        let saved = try #require(try store.task(id: habit.id))
        #expect(saved.startDay == day(12))
        #expect(saved.lengthDays == 14)
        let rows = try store.schedules(taskID: habit.id)
        #expect(rows.count == 1)
        #expect(rows.first?.effectiveFrom == day(12))
        #expect(rows.first?.timing == .part(.noon))
    }

    @Test func pastOneTimeTasksAreReadOnly() throws {
        clock.now = TestEnvironment.date(2026, 10, 5, 9)
        let task = try tasks.createOneTime(title: "Yesterday", date: day(5), timing: .anytime)
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        let model = editor(.edit(task.id))
        #expect(model.isReadOnly)
        #expect(!model.canSave)
    }

    // MARK: Delete, end, delete with history

    @Test func deleteOneTime() throws {
        let task = try tasks.createOneTime(title: "Call", date: day(6), timing: .anytime)
        #expect(editor(.edit(task.id)).perform(.deleteOneTime))
        #expect(try store.tasks().isEmpty)
    }

    @Test func endHabitKeepsItsHistory() throws {
        clock.now = TestEnvironment.date(2026, 10, 1, 9)
        let habit = try tasks.createHabit(
            type: .progress, title: "Gym", timing: .anytime, weekdays: .all, startDay: day(1), lengthDays: nil,
            targetMinutes: nil)
        try tasks.complete(taskID: habit.id, day: day(1))
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        #expect(editor(.edit(habit.id)).perform(.endHabit))
        #expect(try store.task(id: habit.id)?.endedOn == day(5))
        #expect(try store.completions(taskID: habit.id).count == 1)
    }

    @Test func deleteWithHistoryRemovesEverything() throws {
        let habit = try tasks.createHabit(
            type: .progress, title: "Gym", timing: .anytime, weekdays: .all, startDay: day(6), lengthDays: nil,
            targetMinutes: nil)
        try tasks.complete(taskID: habit.id, day: day(6))
        #expect(editor(.edit(habit.id)).perform(.deleteWithHistory))
        #expect(try store.tasks().isEmpty)
        #expect(try store.completions(taskID: nil).isEmpty)
    }
}
