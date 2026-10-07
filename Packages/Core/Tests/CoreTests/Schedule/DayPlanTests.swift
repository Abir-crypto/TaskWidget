import Foundation
import Testing

@testable import Core

struct DayPlanTests {
    @Test func sectionsComeInPartOrderThenAnytime() {
        let plan = DayPlan(day: TestCalendar.today, snapshot: Fixtures().snapshot(), now: TestCalendar.today(13))
        #expect(plan.sections.map(\.part) == [.morning, .noon, .evening, .night, nil])
        #expect(plan.isEmpty)
    }

    @Test func itemsGoToTheirPartInDayOrder() {
        var fixtures = Fixtures()
        let anytime = fixtures.oneTime("Anytime", timing: .anytime)
        let noonPart = fixtures.oneTime("Noon part", timing: .part(.noon))
        let noonFixed = fixtures.oneTime("12:30", timing: .fixed(minute: 750))
        let early = fixtures.oneTime("05:00", timing: .fixed(minute: 300))
        let plan = DayPlan(day: TestCalendar.today, snapshot: fixtures.snapshot(), now: TestCalendar.today(13))
        #expect(plan.section(for: .morning)?.items.map(\.task.id) == [early.id])
        #expect(plan.section(for: .noon)?.items.map(\.task.id) == [noonFixed.id, noonPart.id])
        #expect(plan.section(for: nil)?.items.map(\.task.id) == [anytime.id])
        #expect(plan.items.map(\.task.id) == [early.id, noonFixed.id, noonPart.id, anytime.id])
    }

    @Test func phasesOnToday() {
        let plan = DayPlan(day: TestCalendar.today, snapshot: Fixtures().snapshot(), now: TestCalendar.today(13))
        #expect(plan.sections.map(\.phase) == [.ended, .current, .upcoming, .upcoming, .anytime])
        #expect(plan.currentSection?.part == .noon)
    }

    @Test func noPartIsCurrentBeforeMorning() {
        let plan = DayPlan(day: TestCalendar.today, snapshot: Fixtures().snapshot(), now: TestCalendar.today(5))
        #expect(plan.currentSection == nil)
        #expect(plan.section(for: .morning)?.phase == .upcoming)
    }

    @Test func otherDays() {
        let snapshot = Fixtures().snapshot()
        let past = DayPlan(day: TestCalendar.oct(5), snapshot: snapshot, now: TestCalendar.today(13))
        let future = DayPlan(day: TestCalendar.oct(7), snapshot: snapshot, now: TestCalendar.today(13))
        #expect(past.sections.allSatisfy { $0.phase == .past })
        #expect(future.sections.allSatisfy { $0.phase == .future })
    }

    @Test func countsAndProgress() {
        var fixtures = Fixtures()
        let done = fixtures.oneTime("Done", timing: .part(.morning))
        fixtures.complete(done, on: TestCalendar.today)
        fixtures.oneTime("Missed", timing: .part(.morning))
        let read = fixtures.duration("Read", timing: .part(.morning), target: 30)
        fixtures.log(read, minutes: 20, on: TestCalendar.today)
        fixtures.oneTime("Later", timing: .part(.evening))
        let plan = DayPlan(day: TestCalendar.today, snapshot: fixtures.snapshot(), now: TestCalendar.today(13))
        let morning = plan.section(for: .morning)
        #expect(morning?.doneCount == 1)
        #expect(morning?.missedCount == 2)  // Missed and Short
        #expect(morning?.leftCount == 0)
        #expect(plan.section(for: .evening)?.leftCount == 1)
        let item = morning?.items.first { $0.task.id == read.id }
        #expect(item?.minutes == 20)
        #expect(item?.targetMinutes == 30)
        #expect(item?.status == .short)
    }
}
