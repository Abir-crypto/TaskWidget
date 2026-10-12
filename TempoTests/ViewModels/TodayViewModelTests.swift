import Core
import Foundation
import Testing

@testable import Tempo

@MainActor
struct TodayViewModelTests {
    private let clock = TestEnvironment.clock(hour: 9)
    private let store: SwiftDataTaskStore
    private let tasks: TaskManager
    private let model: TodayViewModel

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        tasks = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
        model = TodayViewModel(tasks: tasks, clock: clock)
    }

    private func day(_ day: Int) -> DayKey { DayKey(year: 2026, month: 10, day: day) }

    private func item(_ task: TaskValue) -> DayItem? {
        model.plan(at: clock.now)?.items.first { $0.task.id == task.id }
    }

    @Test func showsTheSelectedDaysPlanInSpecOrder() throws {
        let anytime = try tasks.createOneTime(title: "Anytime", date: day(6), timing: .anytime)
        let evening = try tasks.createOneTime(title: "Evening", date: day(6), timing: .part(.evening))
        let fixed = try tasks.createOneTime(title: "12:30", date: day(6), timing: .fixed(minute: 750))
        let noon = try tasks.createOneTime(title: "Noon", date: day(6), timing: .part(.noon))
        model.load()
        let plan = try #require(model.plan(at: clock.now))
        #expect(plan.sections.map(\.part) == [.morning, .noon, .evening, .night, nil])
        #expect(plan.items.map(\.task.id) == [fixed.id, noon.id, evening.id, anytime.id])
        #expect(model.title == "Today")
    }

    @Test func statusesChangeAtPartBoundaries() throws {
        let task = try tasks.createOneTime(title: "Noon", date: day(6), timing: .part(.noon))
        model.load()
        let before = TestEnvironment.date(2026, 10, 6, 11, 59)
        let during = TestEnvironment.date(2026, 10, 6, 12, 0)
        let after = TestEnvironment.date(2026, 10, 6, 17, 0)
        #expect(model.plan(at: before)?.items.first { $0.task.id == task.id }?.status == .upcoming)
        #expect(model.plan(at: during)?.items.first { $0.task.id == task.id }?.status == .open)
        #expect(model.plan(at: after)?.items.first { $0.task.id == task.id }?.status == .missed)
        #expect(model.plan(at: during)?.currentSection?.part == .noon)
        #expect(model.plan(at: after)?.section(for: .noon)?.phase == .ended)
    }

    @Test func endedPartsCollapseAndExpand() throws {
        try tasks.createOneTime(title: "Morning", date: day(6), timing: .part(.morning))
        clock.now = TestEnvironment.date(2026, 10, 6, 13)
        model.load()
        let morning = try #require(model.plan(at: clock.now)?.section(for: .morning))
        #expect(model.isCollapsed(morning))
        model.toggleExpanded(.morning)
        #expect(!model.isCollapsed(morning))
        model.toggleExpanded(.morning)
        #expect(model.isCollapsed(morning))
        let noon = try #require(model.plan(at: clock.now)?.section(for: .noon))
        #expect(!model.isCollapsed(noon))
    }

    @Test func dayStripDotsAndWeeks() throws {
        clock.now = TestEnvironment.date(2026, 10, 5, 9)
        try tasks.createOneTime(title: "Missed Monday", date: day(5), timing: .part(.morning))
        try tasks.createOneTime(title: "Thursday", date: day(8), timing: .part(.morning))
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        model.load()
        let week = model.week(at: clock.now)
        #expect(week.map(\.day) == (5...11).map { day($0) })
        #expect(week[0].dot == .missed)
        #expect(week[1].dot == .none)
        #expect(week[1].isToday)
        #expect(week[3].dot == .tasks)

        model.moveWeek(by: 1)
        #expect(model.selectedDay == day(13))
        #expect(!model.isShowingToday)
        model.moveWeek(by: -2)
        #expect(model.selectedDay == DayKey(year: 2026, month: 9, day: 29))
        model.goToToday()
        #expect(model.isShowingToday)
    }

    @Test func dayTitles() {
        model.select(day(7))
        #expect(model.title == "Tomorrow")
        model.select(day(5))
        #expect(model.title == "Yesterday")
        model.select(day(8))
        #expect(model.title != "Tomorrow")
        #expect(model.title.contains("8"))
    }

    @Test func pastDaysAreReadOnly() throws {
        clock.now = TestEnvironment.date(2026, 10, 5, 9)
        let task = try tasks.createOneTime(title: "Monday", date: day(5), timing: .part(.noon))
        let habit = try tasks.createHabit(
            type: .duration, title: "Read", timing: .anytime, weekdays: .all, startDay: day(5), lengthDays: nil,
            targetMinutes: 30)
        clock.now = TestEnvironment.date(2026, 10, 6, 13)  // after the correction window (SPEC §5.11)
        model.select(day(5))
        model.load()
        let oneTime = try #require(item(task))
        let read = try #require(item(habit))
        #expect(!model.canComplete(oneTime))
        #expect(!model.canMove(oneTime))
        #expect(!model.canEditOrDelete(oneTime))
        #expect(!model.canLogTime(read))
        #expect(!model.canEditOrDelete(read))
    }

    @Test func futureDaysFollowF04() throws {
        let task = try tasks.createOneTime(title: "Thursday", date: day(8), timing: .part(.noon))
        let habit = try tasks.createHabit(
            type: .progress, title: "Medicine", timing: .anytime, weekdays: .all, startDay: day(6), lengthDays: nil,
            targetMinutes: nil)
        let read = try tasks.createHabit(
            type: .duration, title: "Read", timing: .anytime, weekdays: .all, startDay: day(6), lengthDays: nil,
            targetMinutes: 30)
        model.select(day(8))
        model.load()
        let oneTime = try #require(item(task))
        #expect(model.canComplete(oneTime))
        #expect(model.canMove(oneTime))
        #expect(model.canEditOrDelete(oneTime))
        #expect(!model.canComplete(try #require(item(habit))))
        #expect(!model.canLogTime(try #require(item(read))))
        model.toggleCompletion(oneTime)
        #expect(item(task)?.status == .done)
    }

    @Test func todaysActionsWork() throws {
        let task = try tasks.createOneTime(title: "Call", date: day(6), timing: .part(.noon))
        let read = try tasks.createHabit(
            type: .duration, title: "Read", timing: .part(.evening), weekdays: .all, startDay: day(6), lengthDays: nil,
            targetMinutes: 30)
        model.load()
        let call = try #require(item(task))
        #expect(model.canComplete(call))
        #expect(model.canLogTime(try #require(item(read))))
        model.toggleCompletion(call)
        #expect(item(task)?.status == .done)
        #expect(model.completions == 1)  // a haptic for completing (T-31)
        #expect(!model.canMove(try #require(item(task))))  // done tasks don't move (D-060)
        model.toggleCompletion(try #require(item(task)))
        #expect(model.completions == 1)  // none for undoing
        model.moveToNextDay(try #require(item(task)))
        #expect(item(task) == nil)
        #expect(try store.task(id: task.id)?.date == day(7))
    }

    @Test func deletesNeedTheRightKind() throws {
        let task = try tasks.createOneTime(title: "Call", date: day(6), timing: .part(.noon))
        let habit = try tasks.createHabit(
            type: .progress, title: "Gym", timing: .anytime, weekdays: .all, startDay: day(6), lengthDays: nil,
            targetMinutes: nil)
        model.load()
        model.requestDelete(try #require(item(task)))
        #expect(model.pendingDelete?.task.id == task.id)
        model.deleteOneTime(try #require(item(task)))
        model.endHabit(try #require(item(habit)))
        #expect(try store.task(id: task.id) == nil)
        #expect(try store.task(id: habit.id)?.endedOn == day(5))
    }

    @Test func linksFocusADayPartOrTask() throws {
        let task = try tasks.createOneTime(title: "Thursday", date: day(8), timing: .part(.noon))
        model.load()
        model.focus(TodayFocus(day: day(8), part: nil, taskID: task.id))
        #expect(model.selectedDay == day(8))
        #expect(model.scrollTarget == Occurrence.id(taskID: task.id, day: day(8)))
        model.focus(TodayFocus(day: nil, part: .evening, taskID: nil))
        #expect(model.selectedDay == day(6))
        #expect(model.scrollTarget == "evening")
    }
}
