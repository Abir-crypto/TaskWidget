import Foundation
import Testing

@testable import Core

struct StatusRulesTests {
    @Test func noonTaskThroughTheDay() {
        var fixtures = Fixtures()
        let task = fixtures.oneTime("Call the bank", timing: .part(.noon))
        #expect(fixtures.status(task, at: TestCalendar.today(11, 59)) == .upcoming)
        #expect(fixtures.status(task, at: TestCalendar.today(12, 0)) == .open)
        #expect(fixtures.status(task, at: TestCalendar.today(16, 59)) == .open)
        #expect(fixtures.status(task, at: TestCalendar.today(17, 0)) == .missed)
        fixtures.complete(task, on: TestCalendar.today)  // at 18:00 the same day
        #expect(fixtures.status(task, at: TestCalendar.today(18, 0)) == .done)
    }

    @Test func fixedTimeTaskIsMissedWhenItsPartEnds() {
        var fixtures = Fixtures()
        let task = fixtures.oneTime("Interview", timing: .fixed(minute: 750))
        #expect(fixtures.status(task, at: TestCalendar.today(11, 59)) == .upcoming)
        #expect(fixtures.status(task, at: TestCalendar.today(12, 0)) == .open)
        #expect(fixtures.status(task, at: TestCalendar.today(13, 0)) == .open)  // after 12:30, still in Noon
        #expect(fixtures.status(task, at: TestCalendar.today(16, 59)) == .open)
        #expect(fixtures.status(task, at: TestCalendar.today(17, 0)) == .missed)
    }

    @Test func anytimeTaskIsMissedAtMidnight() {
        var fixtures = Fixtures()
        let task = fixtures.oneTime("Renew passport", timing: .anytime)
        #expect(fixtures.status(task, at: TestCalendar.today(0, 0)) == .open)
        #expect(fixtures.status(task, at: TestCalendar.today(23, 59)) == .open)
        #expect(fixtures.status(task, at: TestCalendar.date(2026, 10, 7, 0, 0)) == .missed)
    }

    @Test func nightTaskIsMissedAtMidnight() {
        var fixtures = Fixtures()
        let task = fixtures.oneTime("Plan tomorrow", timing: .part(.night))
        #expect(fixtures.status(task, at: TestCalendar.today(20, 59)) == .upcoming)
        #expect(fixtures.status(task, at: TestCalendar.today(23, 59)) == .open)
        #expect(fixtures.status(task, at: TestCalendar.date(2026, 10, 7, 0, 0)) == .missed)
    }

    @Test func earlyFixedTimeWaitsForMorning() {
        // A 05:00 task belongs to Morning, which opens at 06:00.
        var fixtures = Fixtures()
        let task = fixtures.oneTime(timing: .fixed(minute: 300))
        #expect(fixtures.status(task, at: TestCalendar.today(5, 0)) == .upcoming)
        #expect(fixtures.status(task, at: TestCalendar.today(6, 0)) == .open)
        #expect(fixtures.status(task, at: TestCalendar.today(12, 0)) == .missed)
    }

    @Test func durationHabitAtItsPartsEnd() {
        let end = TestCalendar.today(21, 0)  // Evening ends
        var short = Fixtures()
        let shortTask = short.duration(timing: .part(.evening), target: 30)
        short.log(shortTask, minutes: 20, on: TestCalendar.today)
        #expect(short.status(shortTask, at: end) == .short)

        var missed = Fixtures()
        let missedTask = missed.duration(timing: .part(.evening), target: 30)
        #expect(missed.status(missedTask, at: end) == .missed)

        var done = Fixtures()
        let doneTask = done.duration(timing: .part(.evening), target: 30)
        done.log(doneTask, minutes: 30, on: TestCalendar.today)
        #expect(done.status(doneTask, at: end) == .done)
    }

    @Test func durationHabitIsDoneAsSoonAsItReachesTheTarget() {
        var fixtures = Fixtures()
        let task = fixtures.duration(timing: .part(.evening), target: 30)
        fixtures.log(task, minutes: 29, on: TestCalendar.today, seconds: 59)
        #expect(fixtures.status(task, at: TestCalendar.today(18, 0)) == .open)  // 29 min: rounded down
        fixtures.log(task, minutes: 0, on: TestCalendar.today, seconds: 1)
        #expect(fixtures.status(task, at: TestCalendar.today(18, 0)) == .done)
        #expect(fixtures.status(task, at: TestCalendar.today(15, 0)) == .done)  // even before its part starts
    }

    @Test func shortNeedsAWholeMinute() {
        var fixtures = Fixtures()
        let task = fixtures.duration(timing: .part(.morning), target: 30)
        fixtures.log(task, minutes: 0, on: TestCalendar.today, seconds: 59)
        #expect(fixtures.status(task, at: TestCalendar.today(13, 0)) == .missed)
    }

    @Test func pastAndFutureDays() {
        var fixtures = Fixtures()
        let habit = fixtures.habit(timing: .part(.noon))
        #expect(fixtures.status(habit, on: TestCalendar.oct(5), at: TestCalendar.today(9)) == .missed)
        #expect(fixtures.status(habit, on: TestCalendar.oct(7), at: TestCalendar.today(23)) == .upcoming)
        fixtures.complete(habit, on: TestCalendar.oct(5))
        #expect(fixtures.status(habit, on: TestCalendar.oct(5), at: TestCalendar.today(9)) == .done)
    }

    @Test func futureOneTimeTaskCompletedEarlyIsDone() {
        var fixtures = Fixtures()
        let task = fixtures.oneTime(on: TestCalendar.oct(8))
        fixtures.complete(task, on: TestCalendar.oct(8))
        #expect(fixtures.status(task, on: TestCalendar.oct(8), at: TestCalendar.today(9)) == .done)
    }

    @Test func changedPartTimesMoveStatusesImmediately() throws {
        var fixtures = Fixtures()
        let task = fixtures.oneTime(timing: .part(.noon))
        let occurrence = try #require(fixtures.occurrence(task))
        let now = TestCalendar.today(16, 30)
        #expect(fixtures.snapshot().status(of: occurrence, now: now) == .open)
        var earlier = SettingsValue.defaults
        earlier.parts = earlier.parts.setting(.evening, to: 960)  // Evening from 16:00
        #expect(fixtures.snapshot(settings: earlier).status(of: occurrence, now: now) == .missed)
    }

    @Test func undoneCompletionsDontCount() throws {
        var fixtures = Fixtures()
        let task = fixtures.oneTime(timing: .part(.noon))
        fixtures.complete(task, on: TestCalendar.today)
        var data = fixtures.data
        data.completions[0].deletedAt = TestCalendar.today(13)
        let snapshot = Snapshot(data: data, settings: .defaults, calendar: TestCalendar.london)
        let occurrence = try #require(snapshot.engine.occurrence(of: task, on: TestCalendar.today))
        #expect(snapshot.status(of: occurrence, now: TestCalendar.today(13)) == .open)
    }

    @Test func statusHelpers() {
        #expect(Status.short.countsAsMissed)
        #expect(Status.missed.countsAsMissed)
        #expect(!Status.done.countsAsMissed)
        #expect(Status.done.isFinal)
        #expect(!Status.open.isFinal)
        #expect(Status.upcoming.isPending)
    }
}
