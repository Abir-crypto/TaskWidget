import Foundation
import Testing

@testable import Core

struct EditabilityTests {
    private let today = TestCalendar.today
    private let calendar = TestCalendar.london

    @Test func todayAllowsEverything() throws {
        var fixtures = Fixtures()
        let oneTime = fixtures.oneTime(timing: .part(.morning))
        let progress = fixtures.habit(timing: .part(.morning))
        let duration = fixtures.duration(timing: .part(.morning))
        #expect(Editability.canComplete(try #require(fixtures.occurrence(oneTime)), today: today))
        #expect(Editability.canComplete(try #require(fixtures.occurrence(progress)), today: today))
        #expect(Editability.canLogTime(task: duration, day: today, today: today, calendar: calendar))
        let missed = try #require(fixtures.occurrence(oneTime))
        #expect(Editability.canMove(missed, status: .missed, today: today))
        #expect(Editability.canEditOneTime(oneTime, today: today))
    }

    @Test func pastDaysAllowNothing() throws {
        var fixtures = Fixtures()
        let oneTime = fixtures.oneTime(on: TestCalendar.oct(5))
        let progress = fixtures.habit()
        let duration = fixtures.duration()
        let pastOneTime = try #require(fixtures.occurrence(oneTime, on: TestCalendar.oct(5)))
        #expect(!Editability.canComplete(pastOneTime, today: today))
        #expect(
            !Editability.canComplete(try #require(fixtures.occurrence(progress, on: TestCalendar.oct(5))), today: today)
        )
        #expect(!Editability.canLogTime(task: duration, day: TestCalendar.oct(5), today: today, calendar: calendar))
        #expect(!Editability.canMove(pastOneTime, status: .missed, today: today))
        #expect(!Editability.canEditOneTime(oneTime, today: today))
        let entry = TimeEntryValue(
            taskID: duration.id, day: TestCalendar.oct(5), seconds: 60, source: .manual,
            createdAt: TestCalendar.today(9))
        #expect(!Editability.canDeleteTimeEntry(entry, today: today))
    }

    @Test func futureOneTimeTasksCanBeCompletedEarlyAndMoved() throws {
        var fixtures = Fixtures()
        let task = fixtures.oneTime(on: TestCalendar.oct(8))
        let occurrence = try #require(fixtures.occurrence(task, on: TestCalendar.oct(8)))
        #expect(Editability.canComplete(occurrence, today: today))
        #expect(Editability.canMove(occurrence, status: .upcoming, today: today))
        #expect(Editability.canEditOneTime(task, today: today))
        #expect(
            Editability.movePlan(for: occurrence, status: .upcoming, today: today, calendar: calendar)
                == .moveDate(to: TestCalendar.oct(9)))
    }

    @Test func futureHabitsCantBeCompletedOrLogged() throws {
        var fixtures = Fixtures()
        let progress = fixtures.habit()
        let duration = fixtures.duration()
        #expect(
            !Editability.canComplete(try #require(fixtures.occurrence(progress, on: TestCalendar.oct(7))), today: today)
        )
        #expect(!Editability.canLogTime(task: duration, day: TestCalendar.oct(7), today: today, calendar: calendar))
    }

    @Test func durationHabitsAreNeverCheckedOff() throws {
        var fixtures = Fixtures()
        let duration = fixtures.duration()
        #expect(!Editability.canComplete(try #require(fixtures.occurrence(duration)), today: today))
    }

    @Test func timeCanBeLoggedOnUnscheduledLiveDaysOnly() {
        var fixtures = Fixtures()
        let unscheduled = fixtures.duration(weekdays: [.monday])  // today is Tuesday
        let notStarted = fixtures.duration(start: TestCalendar.oct(10))
        #expect(Editability.canLogTime(task: unscheduled, day: today, today: today, calendar: calendar))
        #expect(!Editability.canLogTime(task: notStarted, day: today, today: today, calendar: calendar))
        var ended = fixtures.duration()
        ended.endedOn = TestCalendar.oct(5)
        #expect(!Editability.canLogTime(task: ended, day: today, today: today, calendar: calendar))
    }

    @Test func moveToTomorrowMovesOrCopies() throws {
        var fixtures = Fixtures()
        let task = fixtures.oneTime(timing: .part(.morning))
        let occurrence = try #require(fixtures.occurrence(task))
        #expect(
            Editability.movePlan(for: occurrence, status: .open, today: today, calendar: calendar)
                == .moveDate(to: TestCalendar.oct(7)))
        #expect(
            Editability.movePlan(for: occurrence, status: .missed, today: today, calendar: calendar)
                == .copy(to: TestCalendar.oct(7)))
        #expect(Editability.movePlan(for: occurrence, status: .done, today: today, calendar: calendar) == nil)
    }

    @Test func habitsCantMove() throws {
        var fixtures = Fixtures()
        let habit = fixtures.habit()
        #expect(!Editability.canMove(try #require(fixtures.occurrence(habit)), status: .open, today: today))
    }

    @Test func endedHabitSchedulesAreFrozen() {
        var fixtures = Fixtures()
        let active = fixtures.habit()
        let ended = fixtures.habit(endedOn: TestCalendar.oct(5))
        #expect(Editability.canEditHabitSchedule(active, today: today, calendar: calendar))
        #expect(!Editability.canEditHabitSchedule(ended, today: today, calendar: calendar))
    }
}
