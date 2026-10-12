import Core
import Foundation
import Testing

@testable import Tempo

@MainActor
struct HistoryViewModelTests {
    private let clock = TestEnvironment.clock(hour: 9)
    private let store: SwiftDataTaskStore
    private let tasks: TaskManager
    private let model: HistoryViewModel

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        tasks = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
        model = HistoryViewModel(tasks: tasks, clock: clock)
    }

    private func day(_ day: Int) -> DayKey { DayKey(year: 2026, month: 10, day: day) }

    @Test func completedTasksAreGroupedByTheDayTheyWereDoneNewestFirst() throws {
        clock.now = TestEnvironment.date(2026, 10, 4, 9)
        let sunday = try tasks.createOneTime(title: "Sunday", date: day(4), timing: .anytime)
        try tasks.complete(taskID: sunday.id, day: day(4))
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        let first = try tasks.createOneTime(title: "First today", date: day(6), timing: .anytime)
        try tasks.complete(taskID: first.id, day: day(6))
        clock.advance(by: 60)
        let early = try tasks.createOneTime(title: "Thursday, done early", date: day(8), timing: .anytime)
        try tasks.complete(taskID: early.id, day: day(8))
        try tasks.createOneTime(title: "Not done", date: day(6), timing: .anytime)
        model.load()

        #expect(model.completedGroups.map(\.day) == [day(6), day(4)])
        #expect(model.completedGroups.first?.title == "Today")
        #expect(model.completedGroups.first?.tasks.map(\.task.id) == [early.id, first.id])
        #expect(model.completedGroups.last?.tasks.map(\.task.id) == [sunday.id])
    }

    @Test func onlyEditableCompletionsCanBeUndone() throws {
        clock.now = TestEnvironment.date(2026, 10, 5, 9)
        let yesterday = try tasks.createOneTime(title: "Yesterday", date: day(5), timing: .anytime)
        try tasks.complete(taskID: yesterday.id, day: day(5))
        clock.now = TestEnvironment.date(2026, 10, 6, 13)  // after the correction window (SPEC §5.11)
        let today = try tasks.createOneTime(title: "Today", date: day(6), timing: .anytime)
        try tasks.complete(taskID: today.id, day: day(6))
        model.load()
        let items = model.completedGroups.flatMap(\.tasks)
        let todayItem = try #require(items.first { $0.task.id == today.id })
        let yesterdayItem = try #require(items.first { $0.task.id == yesterday.id })
        #expect(todayItem.canUndo)
        #expect(!yesterdayItem.canUndo)
        model.markNotDone(yesterdayItem)
        #expect(try store.completions(taskID: yesterday.id).count == 1)
        model.markNotDone(todayItem)
        #expect(try store.completions(taskID: today.id).isEmpty)
        #expect(!model.completedGroups.flatMap(\.tasks).contains { $0.task.id == today.id })
    }

    @Test func endedHabitsShowTheirResults() throws {
        clock.now = TestEnvironment.date(2026, 10, 1, 9)
        let medicine = try tasks.createHabit(
            type: .progress, title: "Medicine", timing: .anytime, weekdays: .all, startDay: day(1), lengthDays: 3,
            targetMinutes: nil)
        try tasks.complete(taskID: medicine.id, day: day(1))
        clock.advance(by: 60)
        let read = try tasks.createHabit(
            type: .duration, title: "Read", timing: .anytime, weekdays: .all, startDay: day(1), lengthDays: nil,
            targetMinutes: 30)
        try tasks.logTime(taskID: read.id, minutes: 30)
        clock.now = TestEnvironment.date(2026, 10, 2, 9)
        try tasks.logTime(taskID: read.id, minutes: 50)
        clock.now = TestEnvironment.date(2026, 10, 3, 9)
        try tasks.logTime(taskID: read.id, minutes: 10)
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        try tasks.endHabit(taskID: read.id)
        let active = try tasks.createHabit(
            type: .progress, title: "Active", timing: .anytime, weekdays: .all, startDay: day(6), lengthDays: nil,
            targetMinutes: nil)
        model.load()

        // Read ended on 5 Oct, Medicine on 3 Oct: most recent first.
        #expect(model.endedHabits.map(\.task.id) == [read.id, medicine.id])
        #expect(model.endedHabits.last?.result == "Done 1 of 3 days")
        let readResult = try #require(model.endedHabits.first?.result)
        #expect(readResult.hasPrefix("On target 2 of 5 days · "))
        #expect(readResult.hasSuffix(" total"))
        #expect(!model.endedHabits.contains { $0.task.id == active.id })
    }

    @Test func startAgainCreatesANewHabitAndKeepsTheOldOne() throws {
        clock.now = TestEnvironment.date(2026, 10, 1, 9)
        let gym = try tasks.createHabit(
            type: .progress, title: "Gym", timing: .anytime, weekdays: .all, startDay: day(1), lengthDays: nil,
            targetMinutes: nil)
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        try tasks.endHabit(taskID: gym.id)
        model.load()
        let ended = try #require(model.endedHabits.first)
        model.startAgain(ended)
        #expect(model.restartedTitle == "Gym")
        let all = try store.tasks()
        #expect(all.count == 2)
        #expect(all.contains { $0.id != gym.id && $0.startDay == day(6) && $0.title == "Gym" })
        #expect(model.endedHabits.map(\.task.id) == [gym.id])
    }

    @Test func searchFiltersByTitle() throws {
        let passport = try tasks.createOneTime(title: "Renew passport", date: day(6), timing: .anytime)
        try tasks.complete(taskID: passport.id, day: day(6))
        let bank = try tasks.createOneTime(title: "Call the bank", date: day(6), timing: .anytime)
        try tasks.complete(taskID: bank.id, day: day(6))
        model.load()
        model.searchText = "PASS"
        #expect(model.completedGroups.flatMap(\.tasks).map(\.task.id) == [passport.id])
        model.searchText = "zzz"
        #expect(model.completedGroups.isEmpty)
        #expect(!model.segmentIsEmpty)
        model.searchText = " "
        #expect(model.completedGroups.flatMap(\.tasks).count == 2)
    }

    @Test func emptySegments() {
        model.load()
        #expect(model.segmentIsEmpty)
        model.segment = .habits
        #expect(model.segmentIsEmpty)
    }
}
