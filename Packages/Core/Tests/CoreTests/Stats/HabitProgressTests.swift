import Foundation
import Testing

@testable import Core

struct HabitProgressTests {
    @Test func weekCountsDoneScheduledDays() {
        var fixtures = Fixtures()
        let habit = fixtures.habit(
            weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday], start: TestCalendar.oct(1))
        for day in [5, 6] { fixtures.complete(habit, on: TestCalendar.oct(day)) }
        fixtures.complete(habit, on: TestCalendar.oct(4))  // last week
        let week = HabitProgress.week(of: habit, snapshot: fixtures.snapshot(), today: TestCalendar.today)
        #expect(week.done == 2)
        #expect(week.scheduled == 5)
    }

    @Test func weekStartsAtTheHabitsStart() {
        var fixtures = Fixtures()
        let habit = fixtures.habit(weekdays: .all, start: TestCalendar.oct(8))
        #expect(HabitProgress.week(of: habit, snapshot: fixtures.snapshot(), today: TestCalendar.today).scheduled == 4)
    }

    @Test func dayOfLength() {
        var fixtures = Fixtures()
        let habit = fixtures.habit(start: DayKey(year: 2026, month: 9, day: 25), length: 30)
        let result = HabitProgress.dayOfLength(of: habit, today: TestCalendar.today, calendar: TestCalendar.london)
        #expect(result?.day == 12)
        #expect(result?.length == 30)
        let ongoing = fixtures.habit()
        #expect(HabitProgress.dayOfLength(of: ongoing, today: TestCalendar.today, calendar: TestCalendar.london) == nil)
        let future = fixtures.habit(start: TestCalendar.oct(10), length: 5)
        #expect(HabitProgress.dayOfLength(of: future, today: TestCalendar.today, calendar: TestCalendar.london) == nil)
        #expect(HabitProgress.hasNotStarted(future, today: TestCalendar.today))
        #expect(!HabitProgress.hasNotStarted(ongoing, today: TestCalendar.today))
    }
}
