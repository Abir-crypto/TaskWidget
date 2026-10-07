import Foundation
import Testing

@testable import Core

struct ScheduleHistoryTests {
    private let now = TestCalendar.today(10)

    @Test func startedHabitGetsANewRowFromToday() throws {
        var fixtures = Fixtures()
        let task = fixtures.habit(weekdays: .all, start: TestCalendar.oct(1))
        let write = ScheduleHistory.edit(
            task: task, schedules: fixtures.data.schedules, timing: .anytime, weekdays: [.monday],
            targetMinutes: nil, today: TestCalendar.today, now: now)
        guard case .insert(let row) = write else {
            Issue.record("Expected an insert, got \(String(describing: write))")
            return
        }
        #expect(row.effectiveFrom == TestCalendar.today)
        #expect(row.weekdays == [.monday])
        #expect(row.taskID == task.id)
    }

    @Test func secondEditTheSameDayUpdatesTodaysRow() throws {
        var fixtures = Fixtures()
        let task = fixtures.habit(weekdays: .all, start: TestCalendar.oct(1))
        fixtures.reschedule(task, from: TestCalendar.today, weekdays: [.monday])
        let todays = try #require(fixtures.data.schedules.first { $0.effectiveFrom == TestCalendar.today })
        let write = ScheduleHistory.edit(
            task: task, schedules: fixtures.data.schedules, timing: .part(.noon), weekdays: [.friday],
            targetMinutes: nil, today: TestCalendar.today, now: now)
        #expect(write?.schedule.id == todays.id)
        guard case .update(let row) = write else {
            Issue.record("Expected an update")
            return
        }
        #expect(row.weekdays == [.friday])
        #expect(row.timing == .part(.noon))
    }

    @Test func habitNotStartedYetUpdatesItsFirstRow() throws {
        var fixtures = Fixtures()
        let task = fixtures.duration(start: TestCalendar.oct(10), target: 30)
        let first = try #require(fixtures.data.schedules.first)
        let write = ScheduleHistory.edit(
            task: task, schedules: fixtures.data.schedules, timing: .fixed(minute: 1080), weekdays: .all,
            targetMinutes: 45, today: TestCalendar.today, now: now)
        guard case .update(let row) = write else {
            Issue.record("Expected an update")
            return
        }
        #expect(row.id == first.id)
        #expect(row.effectiveFrom == TestCalendar.oct(10))
        #expect(row.targetMinutes == 45)
        #expect(row.timing == .fixed(minute: 1080))
    }

    @Test func oneTimeTaskUpdatesItsOnlyRow() throws {
        var fixtures = Fixtures()
        let task = fixtures.oneTime(timing: .anytime)
        let write = ScheduleHistory.edit(
            task: task, schedules: fixtures.data.schedules, timing: .part(.night), weekdays: .none,
            targetMinutes: nil, today: TestCalendar.today, now: now)
        guard case .update(let row) = write else {
            Issue.record("Expected an update")
            return
        }
        #expect(row.effectiveFrom == .distantPast)
        #expect(row.timing == .part(.night))
    }

    @Test func unchangedScheduleWritesNothing() {
        var fixtures = Fixtures()
        let task = fixtures.duration(timing: .part(.evening), weekdays: [.monday, .friday], target: 30)
        let write = ScheduleHistory.edit(
            task: task, schedules: fixtures.data.schedules, timing: .part(.evening), weekdays: [.monday, .friday],
            targetMinutes: 30, today: TestCalendar.today, now: now)
        #expect(write == nil)
    }
}
