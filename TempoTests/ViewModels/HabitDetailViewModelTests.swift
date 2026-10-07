import Core
import Foundation
import Testing

@testable import Tempo

@MainActor
struct HabitDetailViewModelTests {
    private let clock = TestEnvironment.clock(hour: 9)
    private let store: SwiftDataTaskStore
    private let tasks: TaskManager

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        tasks = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
    }

    private func day(_ day: Int, month: Int = 10) -> DayKey { DayKey(year: 2026, month: month, day: day) }

    private func model(_ task: TaskValue) -> HabitDetailViewModel {
        let model = HabitDetailViewModel(tasks: tasks, clock: clock, taskID: task.id)
        model.load()
        return model
    }

    /// A Mon/Wed/Fri progress habit from Mon 21 Sep, done on some days, viewed on Tue 6 Oct at 09:00.
    private func gym() throws -> TaskValue {
        clock.now = TestEnvironment.date(2026, 9, 21, 9)
        let task = try tasks.createHabit(
            type: .progress, title: "Gym", timing: .part(.evening), weekdays: [.monday, .wednesday, .friday],
            startDay: day(21, month: 9), lengthDays: nil, targetMinutes: nil)
        for (month, date) in [(9, 21), (9, 23), (9, 28), (10, 2), (10, 5)] {
            clock.now = TestEnvironment.date(2026, month, date, 20)
            try tasks.complete(taskID: task.id, day: day(date, month: month))
        }
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        return task
    }

    @Test func weekDotsMatchTheData() throws {
        let model = model(try gym())
        #expect(model.week.map(\.day) == (5...11).map { day($0) })
        #expect(
            model.week.map(\.result) == [
                .done, .notScheduled, .upcoming, .notScheduled, .upcoming, .notScheduled, .notScheduled,
            ])
    }

    @Test func monthCalendarMatchesTheData() throws {
        let model = model(try gym())
        #expect(model.monthDays[day(2)] == .done)
        #expect(model.monthDays[day(5)] == .done)
        #expect(model.monthDays[day(7)] == .upcoming)
        #expect(model.monthDays[day(6)] == nil)  // Tuesday isn't scheduled
        #expect(!model.canShowNextMonth)
        #expect(model.canShowPreviousMonth)
        model.showPreviousMonth()
        #expect(model.month == day(1, month: 9))
        #expect(model.monthDays[day(21, month: 9)] == .done)
        #expect(model.monthDays[day(25, month: 9)] == .missed)
        #expect(!model.canShowPreviousMonth)
        model.showNextMonth()
        #expect(model.month == day(1))
    }

    @Test func statsAndStreakMatchTheData() throws {
        let model = model(try gym())
        let week = try #require(model.stats.first { $0.kind == .week })
        #expect(week.rate == CompletionRate(done: 1, counted: 1))
        let month = try #require(model.stats.first { $0.kind == .month })
        #expect(month.rate == CompletionRate(done: 2, counted: 2))
        let year = try #require(model.stats.first { $0.kind == .year })
        // 21, 23, 25, 28, 30 Sep; 2, 5 Oct: 7 counted, 5 done.
        #expect(year.rate == CompletionRate(done: 5, counted: 7))
        #expect(week.minutes == nil)
        #expect(model.streak == Streak(current: 2, best: 2))
        #expect(model.hasData)
    }

    @Test func recentMissedDaysAreNewestFirst() throws {
        let model = model(try gym())
        #expect(model.recentMissed.map(\.day) == [day(30, month: 9), day(25, month: 9)])
    }

    @Test func recentMissedDaysStopAtTen() throws {
        clock.now = TestEnvironment.date(2026, 9, 1, 9)
        let task = try tasks.createHabit(
            type: .progress, title: "Daily", timing: .anytime, weekdays: .all, startDay: day(1, month: 9),
            lengthDays: nil, targetMinutes: nil)
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        let model = model(task)
        #expect(model.recentMissed.count == 10)
        #expect(model.recentMissed.first?.day == day(5))
    }

    @Test func durationStatsIncludeTimeAndTheWeeklyGoal() throws {
        clock.now = TestEnvironment.date(2026, 10, 5, 9)
        let read = try tasks.createHabit(
            type: .duration, title: "Read", timing: .anytime, weekdays: .all, startDay: day(5), lengthDays: nil,
            targetMinutes: 30)
        try tasks.logTime(taskID: read.id, minutes: 40)
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        try tasks.logTime(taskID: read.id, minutes: 15)
        let model = model(read)
        let week = try #require(model.stats.first { $0.kind == .week })
        #expect(week.minutes == 55)
        #expect(week.weeklyGoal == 7 * 30)
        #expect(model.stats.first { $0.kind == .month }?.weeklyGoal == nil)
        #expect(model.targetText == "30 min a day")
        #expect(model.canLogTime)
    }

    @Test func todaysEntriesCanBeDeletedAndPastOnesCant() throws {
        clock.now = TestEnvironment.date(2026, 10, 5, 9)
        let read = try tasks.createHabit(
            type: .duration, title: "Read", timing: .anytime, weekdays: .all, startDay: day(5), lengthDays: nil,
            targetMinutes: 30)
        let past = try tasks.logTime(taskID: read.id, minutes: 40)
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        try tasks.logTime(taskID: read.id, minutes: 15)
        let model = model(read)
        #expect(model.todaysEntries.count == 1)
        let entry = try #require(model.todaysEntries.first)
        #expect(model.canDelete(entry))
        #expect(!model.canDelete(past))
        model.deleteEntry(entry)
        #expect(model.todaysEntries.isEmpty)
        model.deleteEntry(past)
        #expect(model.errorMessage != nil)
        #expect(try store.timeEntries(taskID: read.id).count == 1)
    }

    @Test func lengthTextAndButtons() throws {
        clock.now = TestEnvironment.date(2026, 9, 25, 9)
        let medicine = try tasks.createHabit(
            type: .progress, title: "Medicine", timing: .anytime, weekdays: .all, startDay: day(25, month: 9),
            lengthDays: 30, targetMinutes: nil)
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        let lengthModel = model(medicine)
        #expect(lengthModel.lengthText == "Day 12 of 30")
        #expect(!lengthModel.isEnded)
        #expect(!lengthModel.canLogTime)

        lengthModel.endHabit()
        #expect(lengthModel.isEnded)
        #expect(lengthModel.lengthText.hasPrefix("Ended"))
        lengthModel.startAgain()
        #expect(lengthModel.restarted)
        #expect(try store.tasks().count == 2)
    }

    @Test func newHabitHasNoDataYet() throws {
        let task = try tasks.createHabit(
            type: .progress, title: "New", timing: .part(.evening), weekdays: .all, startDay: day(6), lengthDays: nil,
            targetMinutes: nil)
        let model = model(task)
        #expect(!model.hasData)
        #expect(model.lengthText == "Ongoing")
        let future = try tasks.createHabit(
            type: .progress, title: "Later", timing: .anytime, weekdays: .all, startDay: day(9), lengthDays: nil,
            targetMinutes: nil)
        #expect(self.model(future).lengthText.hasPrefix("Starts"))
    }

    @Test func seeAllOpensMissedFilteredToTheHabit() {
        let router = NavigationRouter()
        let id = UUID()
        router.showMissed(for: id)
        #expect(router.selectedTab == .missed)
        #expect(router.missedTaskFilter == id)
    }
}
