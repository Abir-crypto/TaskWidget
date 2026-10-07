import Core
import Foundation
import Testing

@testable import Tempo

@MainActor
struct StatsViewModelTests {
    private let clock = TestEnvironment.clock(hour: 13)
    private let store: SwiftDataTaskStore
    private let tasks: TaskManager
    private let model: StatsViewModel

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        tasks = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
        model = StatsViewModel(manager: StatsManager(tasks: tasks, clock: clock), clock: clock)
    }

    private func day(_ day: Int, month: Int = 10) -> DayKey { DayKey(year: 2026, month: month, day: day) }

    /// A daily habit from Mon 21 Sep, done every day of the week of 28 Sep and on Mon 5 Oct only.
    private func makeHabit() throws -> TaskValue {
        clock.now = TestEnvironment.date(2026, 9, 21, 9)
        let habit = try tasks.createHabit(
            type: .progress, title: "Medicine", timing: .part(.morning), weekdays: .all, startDay: day(21, month: 9),
            lengthDays: nil, targetMinutes: nil)
        for offset in 0..<7 {
            let date = day(28, month: 9).adding(days: offset, in: TestEnvironment.calendar)
            clock.now = date.date(atMinute: 600, in: TestEnvironment.calendar)
            try tasks.complete(taskID: habit.id, day: date)
        }
        clock.now = TestEnvironment.date(2026, 10, 5, 10)
        try tasks.complete(taskID: habit.id, day: day(5))
        clock.now = TestEnvironment.date(2026, 10, 6, 13)
        return habit
    }

    @Test func everyCardHasDataForTheWeek() throws {
        let habit = try makeHabit()
        model.load()
        let stats = try #require(model.stats)
        #expect(stats.range.first == day(5))
        // Mon done, Tue missed by 13:00.
        #expect(stats.rate == CompletionRate(done: 1, counted: 2))
        #expect(stats.change == 50 - 100)
        #expect(model.changeText == "down 50 points from last week")
        #expect(stats.days.count == 7)
        #expect(stats.streaks.first?.task.id == habit.id)
        #expect(stats.habits.map(\.task.id) == [habit.id])
        #expect(stats.hasHabits)
    }

    @Test func switchingRangesStartsAtTheCurrentPeriod() throws {
        _ = try makeHabit()
        model.load()
        model.kind = .month
        #expect(model.range.first == day(1))
        #expect(model.stats?.days.count == 31)
        model.kind = .year
        #expect(model.range.first == DayKey(year: 2026, month: 1, day: 1))
        #expect(model.stats?.months.count == 12)
    }

    @Test func navigationStaysWithinItsLimits() throws {
        _ = try makeHabit()
        model.load()
        #expect(!model.canGoForward)
        #expect(model.canGoBack)
        model.goBack()
        #expect(model.range.first == day(28, month: 9))
        model.goBack()
        #expect(model.range.first == day(21, month: 9))
        // The habit was created on 21 Sep, so there's nothing before this week.
        #expect(!model.canGoBack)
        model.goBack()
        #expect(model.range.first == day(21, month: 9))
        model.goForward()
        model.goForward()
        #expect(model.range.first == day(5))
        model.goForward()
        #expect(model.range.first == day(5))
    }

    @Test func tappingAMonthShowsIt() throws {
        _ = try makeHabit()
        model.kind = .year
        model.showMonth(MonthRate(year: 2026, month: 9, rate: .empty))
        #expect(model.kind == .month)
        #expect(model.range.first == day(1, month: 9))
    }

    @Test func noHabitsMeansTheEmptyState() throws {
        try tasks.createOneTime(title: "Call", date: day(6), timing: .anytime)
        model.load()
        #expect(model.stats?.hasHabits == false)
        #expect(model.stats?.rate.percent == nil)
        #expect(model.changeText == nil)
    }

    @Test func tappingADayOpensItInToday() {
        let router = NavigationRouter()
        router.selectedTab = .stats
        router.showDay(day(5))
        #expect(router.selectedTab == .today)
        #expect(router.todayFocus?.day == day(5))
        #expect(!router.openedFromLinkThisActivation)
    }
}
