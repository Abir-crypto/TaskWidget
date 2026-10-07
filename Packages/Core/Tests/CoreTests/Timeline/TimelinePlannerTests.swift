import Foundation
import Testing

@testable import Core

struct TimelinePlannerTests {
    private let calendar = TestCalendar.london

    @Test func partStartsAndMidnightForTodayAndTomorrow() {
        let now = TestCalendar.today(9)
        let moments = TimelinePlanner.moments(from: now, snapshot: Fixtures().snapshot(), timerGoal: nil)
        #expect(moments.first == now)
        #expect(moments.contains(TestCalendar.today(12)))
        #expect(moments.contains(TestCalendar.today(17)))
        #expect(moments.contains(TestCalendar.today(21)))
        #expect(moments.contains(TestCalendar.date(2026, 10, 7, 0, 0)))  // midnight
        #expect(moments.contains(TestCalendar.date(2026, 10, 7, 6, 0)))  // tomorrow's Morning
        #expect(moments.contains(TestCalendar.date(2026, 10, 8, 0, 0)))  // the next midnight
        #expect(!moments.contains(TestCalendar.today(6)))  // already past
        #expect(moments == moments.sorted())
        #expect(Set(moments).count == moments.count)
    }

    @Test func fixedTimesAndAnHourBefore() {
        var fixtures = Fixtures()
        fixtures.oneTime("Interview", timing: .fixed(minute: 750))
        fixtures.oneTime("Tomorrow", on: TestCalendar.oct(7), timing: .fixed(minute: 600))
        fixtures.oneTime("Later", on: TestCalendar.oct(9), timing: .fixed(minute: 600))
        let moments = TimelinePlanner.moments(from: TestCalendar.today(9), snapshot: fixtures.snapshot())
        #expect(moments.contains(TestCalendar.today(11, 30)))
        #expect(moments.contains(TestCalendar.today(12, 30)))
        #expect(moments.contains(TestCalendar.date(2026, 10, 7, 9, 0)))
        #expect(moments.contains(TestCalendar.date(2026, 10, 7, 10, 0)))
        #expect(!moments.contains(TestCalendar.date(2026, 10, 9, 10, 0)))  // beyond tomorrow
    }

    @Test func customPartTimesMoveTheMoments() {
        var settings = SettingsValue.defaults
        settings.parts = settings.parts.setting(.evening, to: 1080)
        let snapshot = Fixtures().snapshot(settings: settings)
        let moments = TimelinePlanner.moments(from: TestCalendar.today(9), snapshot: snapshot)
        #expect(moments.contains(TestCalendar.today(18)))
        #expect(!moments.contains(TestCalendar.today(17)))
    }

    @Test func timerTargetReached() {
        let start = TestCalendar.today(18)
        let running = TimerRules.start(kind: .habit, habitID: UUID(), now: start, calendar: calendar)
        let goal = TimelinePlanner.TimerGoal(state: running, loggedSeconds: 10 * 60, targetMinutes: 30)
        #expect(TimelinePlanner.targetReached(goal, now: start) == start.addingTimeInterval(20 * 60))
        let moments = TimelinePlanner.moments(from: start, snapshot: Fixtures().snapshot(), timerGoal: goal)
        #expect(moments.contains(start.addingTimeInterval(20 * 60)))
        let paused = TimelinePlanner.TimerGoal(
            state: TimerRules.pause(running, now: start.addingTimeInterval(60)), loggedSeconds: 600, targetMinutes: 30)
        #expect(TimelinePlanner.targetReached(paused, now: start.addingTimeInterval(120)) == nil)
        let done = TimelinePlanner.TimerGoal(state: running, loggedSeconds: 1_800, targetMinutes: 30)
        #expect(TimelinePlanner.targetReached(done, now: start) == nil)
    }

    @Test func nextMidnight() {
        #expect(
            TimelinePlanner.nextMidnight(after: TestCalendar.today(23, 59), calendar: calendar)
                == TestCalendar.date(2026, 10, 7, 0, 0))
    }
}
