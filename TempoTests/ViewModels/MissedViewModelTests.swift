import Core
import Foundation
import Testing

@testable import Tempo

@MainActor
struct MissedViewModelTests {
    private let clock = TestEnvironment.clock(hour: 9)
    private let store: SwiftDataTaskStore
    private let tasks: TaskManager
    private let model: MissedViewModel

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        tasks = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
        model = MissedViewModel(tasks: tasks, clock: clock)
    }

    private func day(_ day: Int, month: Int = 10) -> DayKey { DayKey(year: 2026, month: month, day: day) }

    private struct Tasks {
        let medicine: TaskValue
        let passport: TaskValue
        let read: TaskValue
        let call: TaskValue
        let stretch: TaskValue
    }

    /// Earlier misses: Medicine on Mon 28 Sep and Mon 5 Oct (Morning); Passport on Tue 29 Sep (12:30); Read on
    /// Tue 29 Sep (no time) and Sat 3 Oct (10 of 30 min). Today at 13:00: Call (Morning, missed) and Stretch
    /// (Morning, 5 of 20 min).
    private func makeTasks() throws -> Tasks {
        clock.now = TestEnvironment.date(2026, 9, 28, 5)
        let medicine = try tasks.createHabit(
            type: .progress, title: "Medicine", timing: .part(.morning), weekdays: [.monday],
            startDay: day(28, month: 9), lengthDays: nil, targetMinutes: nil)
        clock.advance(by: 1)
        let passport = try tasks.createOneTime(title: "Passport", date: day(29, month: 9), timing: .fixed(minute: 750))
        clock.advance(by: 1)
        let read = try tasks.createHabit(
            type: .duration, title: "Read", timing: .part(.evening), weekdays: [.tuesday, .saturday],
            startDay: day(28, month: 9), lengthDays: nil, targetMinutes: 30)
        clock.now = TestEnvironment.date(2026, 10, 3, 9)
        try tasks.logTime(taskID: read.id, minutes: 10)
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        let call = try tasks.createOneTime(title: "Call", date: day(6), timing: .part(.morning))
        clock.advance(by: 1)
        let stretch = try tasks.createHabit(
            type: .duration, title: "Stretch", timing: .part(.morning), weekdays: .all, startDay: day(6),
            lengthDays: nil, targetMinutes: 20)
        try tasks.logTime(taskID: stretch.id, minutes: 5)
        clock.now = TestEnvironment.date(2026, 10, 6, 13)
        return Tasks(medicine: medicine, passport: passport, read: read, call: call, stretch: stretch)
    }

    @Test func todayListsMissedAndShortWithTheirActions() throws {
        let made = try makeTasks()
        model.load()
        #expect(model.todayItems.map(\.occurrence.task.id) == [made.call.id, made.stretch.id])
        let call = try #require(model.todayItems.first)
        let stretch = try #require(model.todayItems.last)
        #expect(stretch.status == .short)
        #expect(model.canMarkDone(call))
        #expect(model.canMove(call))
        #expect(!model.canLogTime(call))
        #expect(model.canLogTime(stretch))
        #expect(!model.canMarkDone(stretch))
        #expect(!model.canMove(stretch))
    }

    @Test func aTaskLeavesTodayAsSoonAsItIsNoLongerMissed() throws {
        let made = try makeTasks()
        model.load()
        model.markDone(try #require(model.todayItems.first))
        #expect(model.todayItems.map(\.occurrence.task.id) == [made.stretch.id])
        try tasks.logTime(taskID: made.stretch.id, minutes: 15)
        model.load()
        #expect(model.todayItems.isEmpty)
    }

    @Test func moveToTomorrowKeepsTheMissAndCopiesTheTask() throws {
        let made = try makeTasks()
        model.load()
        model.moveToTomorrow(try #require(model.todayItems.first))
        let call = try #require(model.todayItems.first)
        #expect(call.occurrence.task.id == made.call.id)
        #expect(try store.tasks().contains { $0.title == "Call" && $0.date == day(7) })
        // The copy exists, so moving again is no longer offered (D-081).
        #expect(!model.canMove(call))
    }

    @Test func earlierIsGroupedByDateNewestFirstWithACount() throws {
        let made = try makeTasks()
        model.load()
        #expect(model.earlierGroups.map(\.day) == [day(5), day(3), day(29, month: 9), day(28, month: 9)])
        #expect(model.earlierGroups[2].items.map(\.occurrence.task.id) == [made.passport.id, made.read.id])
        #expect(model.earlierCount == 5)
        #expect(model.hasEarlier)
        let short = try #require(model.earlierGroups[1].items.first)
        #expect(short.status == .short)
        #expect(short.minutes == 10)
        #expect(model.dueText(model.earlierGroups[2].items[0]).hasSuffix("· \(TimeOfDayFormatter.string(minute: 750))"))
        #expect(model.dueText(model.earlierGroups[0].items[0]).hasSuffix("· Morning"))
    }

    @Test func sortAndFiltersChangeTheListAndTheCount() throws {
        let made = try makeTasks()
        model.load()
        model.filter.sort = .oldestFirst
        #expect(model.earlierGroups.first?.day == day(28, month: 9))
        model.filter.types = [.duration]
        #expect(model.earlierCount == 2)
        #expect(model.filter.isActive)
        model.filter.parts = [.noon]
        #expect(model.earlierCount == 0)
        model.clearFilters()
        #expect(model.earlierCount == 5)
        #expect(model.filter.sort == .oldestFirst)
        #expect(!model.filter.isActive)
        model.filter.dateRange = .thisWeek
        #expect(model.earlierCount == 1)
        model.filter.dateRange = .custom(first: day(29, month: 9), last: day(3))
        #expect(model.earlierCount == 3)
        model.showOnly(taskID: made.medicine.id)
        #expect(model.earlierCount == 2)
        #expect(model.filter.dateRange == .all)
    }

    @Test func filterChoicesIncludeEveryLiveTask() throws {
        let made = try makeTasks()
        try tasks.deleteOneTime(taskID: made.call.id)
        model.load()
        #expect(model.filterableTasks.map(\.title) == ["Medicine", "Passport", "Read", "Stretch"])
        #expect(!model.todayItems.contains { $0.occurrence.task.id == made.call.id })
    }

    @Test func emptyStates() {
        model.load()
        #expect(model.isLoaded)
        #expect(model.todayItems.isEmpty)
        #expect(!model.hasEarlier)
        #expect(model.earlierCount == 0)
    }
}
