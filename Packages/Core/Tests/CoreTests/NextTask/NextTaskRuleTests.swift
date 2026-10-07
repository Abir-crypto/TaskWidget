import Foundation
import Testing

@testable import Core

struct NextTaskRuleTests {
    private func next(_ fixtures: Fixtures, at now: Date) -> NextTask? {
        NextTaskRule.next(in: fixtures.snapshot(), now: now)
    }

    private func then(_ fixtures: Fixtures, at now: Date) -> NextTask? {
        NextTaskRule.then(in: fixtures.snapshot(), now: now)
    }

    @Test func rule1FixedTimeWithinTheHour() {
        var fixtures = Fixtures()
        let interview = fixtures.oneTime("Interview", timing: .fixed(minute: 750))
        fixtures.oneTime("Call the bank", timing: .part(.noon))
        let result = next(fixtures, at: TestCalendar.today(11, 45))
        #expect(result?.occurrence.task.id == interview.id)
        #expect(result?.kind == .fixed(minute: 750))
    }

    @Test func rule2CurrentPartThenTheFixedTask() {
        var fixtures = Fixtures()
        let call = fixtures.oneTime("Call the bank", timing: .part(.noon))
        let late = fixtures.oneTime("Pick up", timing: .fixed(minute: 960))
        let now = TestCalendar.today(13, 0)
        #expect(next(fixtures, at: now)?.occurrence.task.id == call.id)
        #expect(next(fixtures, at: now)?.kind == .currentPart(.noon))
        #expect(then(fixtures, at: now)?.occurrence.task.id == late.id)
        #expect(then(fixtures, at: now)?.kind == .fixed(minute: 960))
    }

    @Test func rule3LaterPartFromItsStart() {
        var fixtures = Fixtures()
        let gym = fixtures.oneTime("Gym", timing: .part(.evening))
        let result = next(fixtures, at: TestCalendar.today(13, 0))
        #expect(result?.occurrence.task.id == gym.id)
        #expect(result?.kind == .laterPart(.evening))
    }

    @Test func rule4AnytimeWhenNothingElseIsLeft() {
        var fixtures = Fixtures()
        let passport = fixtures.oneTime("Renew passport", timing: .anytime)
        let result = next(fixtures, at: TestCalendar.today(22, 0))
        #expect(result?.occurrence.task.id == passport.id)
        #expect(result?.kind == .anytime)
    }

    @Test func rule5NothingOpenIsFree() {
        var fixtures = Fixtures()
        let task = fixtures.oneTime(timing: .anytime)
        fixtures.complete(task, on: TestCalendar.today)
        fixtures.oneTime(timing: .part(.morning))  // missed by 22:00
        #expect(next(fixtures, at: TestCalendar.today(22, 0)) == nil)
        #expect(next(Fixtures(), at: TestCalendar.today(9)) == nil)
    }

    @Test func passedFixedTimesInTheCurrentPartComeFirst() {
        var fixtures = Fixtures()
        fixtures.oneTime("Noon task", timing: .part(.noon))
        let late = fixtures.oneTime("12:40", timing: .fixed(minute: 760))
        let early = fixtures.oneTime("12:30", timing: .fixed(minute: 750))
        let result = next(fixtures, at: TestCalendar.today(14, 0))
        #expect(result?.occurrence.task.id == early.id)
        #expect(result?.kind == .currentPart(.noon))
        #expect(then(fixtures, at: TestCalendar.today(14, 0))?.occurrence.task.id == late.id)
    }

    @Test func partTasksInTheCurrentPartFollowCreationOrder() {
        var fixtures = Fixtures()
        let first = fixtures.oneTime("First", timing: .part(.noon))
        let second = fixtures.habit("Second", timing: .part(.noon))
        #expect(next(fixtures, at: TestCalendar.today(13))?.occurrence.task.id == first.id)
        #expect(then(fixtures, at: TestCalendar.today(13))?.occurrence.task.id == second.id)
    }

    @Test func fixedTimeWinsATieWithAPartStart() {
        var fixtures = Fixtures()
        fixtures.oneTime("Evening", timing: .part(.evening))
        let fixed = fixtures.oneTime("17:00", timing: .fixed(minute: 1020))
        // At 14:00 neither is within the hour; both count at 17:00 and the fixed time wins.
        #expect(next(fixtures, at: TestCalendar.today(14))?.occurrence.task.id == fixed.id)
    }

    @Test func earliestComingItemWins() {
        var fixtures = Fixtures()
        fixtures.oneTime("Night", timing: .part(.night))
        let evening = fixtures.oneTime("Evening", timing: .part(.evening))
        fixtures.oneTime("19:00", timing: .fixed(minute: 1140))
        #expect(next(fixtures, at: TestCalendar.today(13))?.occurrence.task.id == evening.id)
    }

    @Test func beforeMorningNoPartIsInProgress() {
        var fixtures = Fixtures()
        let morning = fixtures.oneTime("Stretch", timing: .part(.morning))
        let result = next(fixtures, at: TestCalendar.today(5, 0))
        #expect(result?.occurrence.task.id == morning.id)
        #expect(result?.kind == .laterPart(.morning))
    }

    @Test func doneAndMissedAreNotCandidates() {
        var fixtures = Fixtures()
        let done = fixtures.oneTime("Done", timing: .part(.noon))
        fixtures.complete(done, on: TestCalendar.today)
        fixtures.oneTime("Missed", timing: .part(.morning))
        let read = fixtures.duration("Read", timing: .part(.morning))
        fixtures.log(read, minutes: 10, on: TestCalendar.today)  // Short by 13:00
        let evening = fixtures.oneTime("Evening", timing: .part(.evening))
        #expect(next(fixtures, at: TestCalendar.today(13))?.occurrence.task.id == evening.id)
    }

    @Test func otherDaysAreIgnored() {
        var fixtures = Fixtures()
        fixtures.oneTime("Tomorrow", on: TestCalendar.oct(7), timing: .part(.noon))
        fixtures.habit("Monday", timing: .part(.noon), weekdays: [.monday])
        #expect(next(fixtures, at: TestCalendar.today(13)) == nil)
    }
}
