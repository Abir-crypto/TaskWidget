import Foundation
import Testing

@testable import Core

struct StatsCalculatorTests {
    private let calendar = TestCalendar.london

    private func calculator(_ fixtures: Fixtures, at now: Date = TestCalendar.today(13)) -> StatsCalculator {
        StatsCalculator(snapshot: fixtures.snapshot(), now: now)
    }

    private func week(_ day: DayKey = TestCalendar.today) -> StatsRange {
        StatsRange.containing(day, kind: .week, calendar: calendar)
    }

    @Test func twentyThreeOfTwentyEightIs82Percent() {
        #expect(CompletionRate(done: 23, counted: 28).percent == 82)
        // A daily habit from Tue 8 Sep to Mon 5 Oct: 28 counted days, done on all but five.
        var fixtures = Fixtures()
        let habit = fixtures.habit(start: DayKey(year: 2026, month: 9, day: 8))
        let skipped: Set<Int> = [20_260_910, 20_260_915, 20_260_920, 20_260_925, 20_261_001]
        for day in DayKey(year: 2026, month: 9, day: 8).through(TestCalendar.oct(5), in: calendar)
        where !skipped.contains(day.rawValue) {
            fixtures.complete(habit, on: day)
        }
        let rate = calculator(fixtures).rate(
            of: habit, from: DayKey(year: 2026, month: 9, day: 8), through: TestCalendar.oct(5))
        #expect(rate == CompletionRate(done: 23, counted: 28))
        #expect(rate.percent == 82)
    }

    @Test func percentRoundsHalfUp() {
        #expect(CompletionRate(done: 1, counted: 8).percent == 13)  // 12.5
        #expect(CompletionRate(done: 1, counted: 3).percent == 33)
        #expect(CompletionRate(done: 2, counted: 3).percent == 67)
        #expect(CompletionRate(done: 0, counted: 5).percent == 0)
        #expect(CompletionRate(done: 5, counted: 5).percent == 100)
    }

    @Test func todaysEveningHabitIsNotCountedAt13() {
        var fixtures = Fixtures()
        let habit = fixtures.habit(timing: .part(.evening), start: TestCalendar.today)
        let stats = calculator(fixtures)
        #expect(stats.rate(of: habit, from: TestCalendar.today, through: TestCalendar.today).counted == 0)
        // Once it's done, it counts.
        fixtures.complete(habit, on: TestCalendar.today)
        #expect(
            calculator(fixtures).rate(of: habit, from: TestCalendar.today, through: TestCalendar.today)
                == CompletionRate(done: 1, counted: 1))
        // And once its part ends undone, it counts as missed.
        var missed = Fixtures()
        let late = missed.habit(timing: .part(.evening), start: TestCalendar.today)
        #expect(
            calculator(missed, at: TestCalendar.today(21)).rate(
                of: late, from: TestCalendar.today, through: TestCalendar.today) == CompletionRate(done: 0, counted: 1))
    }

    @Test func futureDaysDontCount() {
        var fixtures = Fixtures()
        let habit = fixtures.habit(start: TestCalendar.oct(5))
        let stats = calculator(fixtures, at: TestCalendar.today(23, 59))
        // Mon missed, Tue open; Wed–Sun in the future.
        #expect(stats.rate(of: habit, from: week().first, through: week().last) == CompletionRate(done: 0, counted: 1))
    }

    @Test func changeIsHiddenWithoutPreviousData() {
        var fixtures = Fixtures()
        let habit = fixtures.habit(start: TestCalendar.oct(5))
        fixtures.complete(habit, on: TestCalendar.oct(5))
        let stats = calculator(fixtures).stats(for: week())
        #expect(stats.rate.percent == 100)
        #expect(stats.change == nil)
    }

    @Test func changeComparesWithThePreviousRange() {
        var fixtures = Fixtures()
        let habit = fixtures.habit(start: DayKey(year: 2026, month: 9, day: 28))
        // Last week (28 Sep – 4 Oct): done 4 of 7 = 57%. This week so far: Mon done = 100%.
        for day in [28, 29, 30] { fixtures.complete(habit, on: DayKey(year: 2026, month: 9, day: day)) }
        fixtures.complete(habit, on: TestCalendar.oct(1))
        fixtures.complete(habit, on: TestCalendar.oct(5))
        let stats = calculator(fixtures).stats(for: week())
        #expect(stats.change == 100 - 57)
    }

    @Test func durationGoalIncludesDaysStillToCome() {
        var fixtures = Fixtures()
        let read = fixtures.duration(weekdays: .all, start: TestCalendar.oct(5), target: 30)
        fixtures.log(read, minutes: 40, on: TestCalendar.oct(5))
        let stats = calculator(fixtures).stats(for: week())
        #expect(stats.time.count == 1)
        #expect(stats.time.first?.progress == GoalProgress(minutes: 40, goal: 7 * 30))
        #expect(stats.totalMinutes == 40)
    }

    @Test func partRatesAndMostMissedNeedThreeCounted() {
        var fixtures = Fixtures()
        // Morning: 3 counted, 1 done (33%). Evening: 2 counted, 0 done (0%, but under the minimum).
        let morning = fixtures.habit("Morning", timing: .part(.morning), start: TestCalendar.oct(3))
        fixtures.complete(morning, on: TestCalendar.oct(4))
        fixtures.oneTime("Evening 1", on: TestCalendar.oct(4), timing: .part(.evening))
        fixtures.oneTime("Evening 2", on: TestCalendar.oct(5), timing: .fixed(minute: 1080))
        let range = StatsRange(kind: .week, first: TestCalendar.oct(3), last: TestCalendar.oct(5))
        let stats = calculator(fixtures)
        let rates = stats.partRates(from: range.first, through: range.last)
        #expect(rates.first { $0.part == .morning }?.rate == CompletionRate(done: 1, counted: 3))
        #expect(rates.first { $0.part == .evening }?.rate == CompletionRate(done: 0, counted: 2))
        #expect(stats.mostMissed(rates) == .morning)

        fixtures.oneTime("Evening 3", on: TestCalendar.oct(3), timing: .part(.evening))
        let more = calculator(fixtures)
        #expect(more.mostMissed(more.partRates(from: range.first, through: range.last)) == .evening)
    }

    @Test func partRatesCountEveryTypeButOnlyFinalStatuses() {
        var fixtures = Fixtures()
        let task = fixtures.oneTime("Noon", timing: .part(.noon))
        fixtures.complete(task, on: TestCalendar.today)
        fixtures.oneTime("Evening", timing: .part(.evening))  // Upcoming at 13:00
        fixtures.oneTime("Anytime", timing: .anytime)  // Open at 13:00
        let rates = calculator(fixtures).partRates(from: TestCalendar.today, through: TestCalendar.today)
        #expect(rates.first { $0.part == .noon }?.rate == CompletionRate(done: 1, counted: 1))
        #expect(rates.first { $0.part == .evening }?.rate.counted == 0)
        #expect(rates.first { $0.part == .anytime }?.rate.counted == 0)
        #expect(calculator(fixtures).mostMissed(rates) == nil)
    }

    @Test func streakSkipsUnscheduledDaysAndOpenToday() {
        var fixtures = Fixtures()
        let habit = fixtures.habit(
            timing: .part(.evening), weekdays: [.monday, .wednesday, .friday],
            start: DayKey(year: 2026, month: 9, day: 28))
        for day in [28, 30] { fixtures.complete(habit, on: DayKey(year: 2026, month: 9, day: day)) }
        fixtures.complete(habit, on: TestCalendar.oct(2))
        fixtures.complete(habit, on: TestCalendar.oct(5))
        // Today is Tuesday (not scheduled). Through Wednesday's Open evening the streak holds.
        #expect(calculator(fixtures).streak(of: habit) == Streak(current: 4, best: 4))
        #expect(
            calculator(fixtures, at: TestCalendar.date(2026, 10, 7, 18)).streak(of: habit)
                == Streak(current: 4, best: 4))
        // Wednesday ends undone: the streak breaks, the best stays.
        #expect(
            calculator(fixtures, at: TestCalendar.date(2026, 10, 7, 21)).streak(of: habit)
                == Streak(current: 0, best: 4))
    }

    @Test func doneTodayExtendsTheStreak() {
        var fixtures = Fixtures()
        let habit = fixtures.habit(start: TestCalendar.oct(5))
        fixtures.complete(habit, on: TestCalendar.oct(5))
        fixtures.complete(habit, on: TestCalendar.today)
        #expect(calculator(fixtures).streak(of: habit) == Streak(current: 2, best: 2))
    }

    @Test func bestIsTheLongestRunEver() {
        var fixtures = Fixtures()
        let habit = fixtures.habit(start: TestCalendar.oct(1))
        for day in [1, 2, 3] { fixtures.complete(habit, on: TestCalendar.oct(day)) }
        fixtures.complete(habit, on: TestCalendar.oct(5))
        #expect(calculator(fixtures, at: TestCalendar.today(9)).streak(of: habit) == Streak(current: 1, best: 3))
    }

    @Test func streaksAreSortedByCurrentStreak() {
        var fixtures = Fixtures()
        let low = fixtures.habit("Low", start: TestCalendar.oct(4))
        let high = fixtures.habit("High", start: TestCalendar.oct(4))
        fixtures.complete(high, on: TestCalendar.oct(4))
        fixtures.complete(high, on: TestCalendar.oct(5))
        fixtures.complete(low, on: TestCalendar.oct(5))
        let stats = calculator(fixtures).stats(for: week())
        #expect(stats.streaks.map(\.task.id) == [high.id, low.id])
    }

    @Test func noHabitsMeansNoRate() {
        var fixtures = Fixtures()
        fixtures.oneTime(timing: .part(.morning))
        let stats = calculator(fixtures).stats(for: week())
        #expect(stats.rate.percent == nil)
        #expect(!stats.hasHabits)
        #expect(stats.change == nil)
    }

    @Test func oneTimeTasksCountWhenCompleted() {
        var fixtures = Fixtures()
        let done = fixtures.oneTime(on: TestCalendar.oct(5))
        fixtures.complete(done, on: TestCalendar.oct(5))
        fixtures.oneTime(on: TestCalendar.oct(5))
        let early = fixtures.oneTime(on: TestCalendar.oct(9))  // completed early; date not reached yet
        fixtures.complete(early, on: TestCalendar.oct(9))
        #expect(calculator(fixtures).stats(for: week()).oneTimeCompleted == 1)
    }

    @Test func chartsHaveADayOrMonthEach() {
        var fixtures = Fixtures()
        let habit = fixtures.habit(start: TestCalendar.oct(5))
        fixtures.complete(habit, on: TestCalendar.oct(5))
        let stats = calculator(fixtures)
        let weekStats = stats.stats(for: week())
        #expect(weekStats.days.count == 7)
        #expect(weekStats.days.first?.rate == CompletionRate(done: 1, counted: 1))
        #expect(weekStats.months.isEmpty)
        let year = stats.stats(for: StatsRange.containing(TestCalendar.today, kind: .year, calendar: calendar))
        #expect(year.months.count == 12)
        #expect(year.months[9].rate == CompletionRate(done: 1, counted: 1))
        #expect(year.days.count == 365)
    }

    @Test func habitsListOnlyHabitsLiveInTheRange() {
        var fixtures = Fixtures()
        let current = fixtures.habit("Current", start: TestCalendar.oct(1))
        fixtures.habit(
            "Old", start: DayKey(year: 2026, month: 9, day: 1), endedOn: DayKey(year: 2026, month: 9, day: 20))
        fixtures.habit("Future", start: TestCalendar.oct(20))
        #expect(calculator(fixtures).stats(for: week()).habits.map(\.task.id) == [current.id])
    }

    @Test func rangesAndNavigation() {
        let month = StatsRange.containing(TestCalendar.today, kind: .month, calendar: calendar)
        #expect(month.first == TestCalendar.oct(1))
        #expect(month.last == TestCalendar.oct(31))
        #expect(month.previous(in: calendar).first == DayKey(year: 2026, month: 9, day: 1))
        #expect(month.previous(in: calendar).last == DayKey(year: 2026, month: 9, day: 30))
        #expect(!month.canGoForward(today: TestCalendar.today, calendar: calendar))
        #expect(month.previous(in: calendar).canGoForward(today: TestCalendar.today, calendar: calendar))
        #expect(month.canGoBack(firstDay: DayKey(year: 2026, month: 9, day: 15), calendar: calendar))
        #expect(!month.canGoBack(firstDay: TestCalendar.oct(2), calendar: calendar))
        #expect(!month.canGoBack(firstDay: nil, calendar: calendar))
        let weekRange = week()
        #expect(weekRange.first == TestCalendar.oct(5))
        #expect(weekRange.next(in: calendar).first == TestCalendar.oct(12))
        let year = StatsRange.containing(TestCalendar.today, kind: .year, calendar: calendar)
        #expect(year.first == DayKey(year: 2026, month: 1, day: 1))
        #expect(year.last == DayKey(year: 2026, month: 12, day: 31))
    }

    @Test func firstDayIsWhenTheFirstTaskWasCreated() {
        var fixtures = Fixtures()
        fixtures.habit()
        #expect(calculator(fixtures).firstDay == DayKey(year: 2026, month: 9, day: 1))
        #expect(calculator(Fixtures()).firstDay == nil)
    }

    @Test func statusesForWeekDotsAndCalendar() {
        var fixtures = Fixtures()
        let habit = fixtures.habit(
            timing: .part(.evening), weekdays: [.monday, .tuesday, .thursday], start: TestCalendar.oct(5))
        fixtures.complete(habit, on: TestCalendar.oct(5))
        let statuses = calculator(fixtures).statuses(of: habit, from: week().first, through: week().last)
        #expect(statuses[TestCalendar.oct(5)] == .done)
        #expect(statuses[TestCalendar.oct(6)] == .upcoming)
        #expect(statuses[TestCalendar.oct(7)] == nil)  // not scheduled
        #expect(statuses[TestCalendar.oct(8)] == .upcoming)
    }
}
