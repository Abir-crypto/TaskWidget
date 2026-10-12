import Foundation
import Testing

@testable import Core

struct EditabilityTests {
    private let today = TestCalendar.today
    private let calendar = TestCalendar.london
    /// Tuesday 6 Oct with the correction window closed, as at 12:00 or later.
    private var window: EditWindow { EditWindow(today: today) }

    @Test func todayAllowsEverything() throws {
        var fixtures = Fixtures()
        let oneTime = fixtures.oneTime(timing: .part(.morning))
        let progress = fixtures.habit(timing: .part(.morning))
        let duration = fixtures.duration(timing: .part(.morning))
        #expect(Editability.canComplete(try #require(fixtures.occurrence(oneTime)), in: window))
        #expect(Editability.canComplete(try #require(fixtures.occurrence(progress)), in: window))
        #expect(Editability.canLogTime(task: duration, day: today, in: window, calendar: calendar))
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
        #expect(!Editability.canComplete(pastOneTime, in: window))
        #expect(
            !Editability.canComplete(try #require(fixtures.occurrence(progress, on: TestCalendar.oct(5))), in: window)
        )
        #expect(!Editability.canLogTime(task: duration, day: TestCalendar.oct(5), in: window, calendar: calendar))
        #expect(!Editability.canMove(pastOneTime, status: .missed, today: today))
        #expect(!Editability.canEditOneTime(oneTime, today: today))
        let entry = TimeEntryValue(
            taskID: duration.id, day: TestCalendar.oct(5), seconds: 60, source: .manual,
            createdAt: TestCalendar.today(9))
        #expect(!Editability.canDeleteTimeEntry(entry, in: window))
    }

    @Test func futureOneTimeTasksCanBeCompletedEarlyAndMoved() throws {
        var fixtures = Fixtures()
        let task = fixtures.oneTime(on: TestCalendar.oct(8))
        let occurrence = try #require(fixtures.occurrence(task, on: TestCalendar.oct(8)))
        #expect(Editability.canComplete(occurrence, in: window))
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
            !Editability.canComplete(try #require(fixtures.occurrence(progress, on: TestCalendar.oct(7))), in: window)
        )
        #expect(!Editability.canLogTime(task: duration, day: TestCalendar.oct(7), in: window, calendar: calendar))
    }

    @Test func durationHabitsAreNeverCheckedOff() throws {
        var fixtures = Fixtures()
        let duration = fixtures.duration()
        #expect(!Editability.canComplete(try #require(fixtures.occurrence(duration)), in: window))
    }

    @Test func timeCanBeLoggedOnUnscheduledLiveDaysOnly() {
        var fixtures = Fixtures()
        let unscheduled = fixtures.duration(weekdays: [.monday])  // today is Tuesday
        let notStarted = fixtures.duration(start: TestCalendar.oct(10))
        #expect(Editability.canLogTime(task: unscheduled, day: today, in: window, calendar: calendar))
        #expect(!Editability.canLogTime(task: notStarted, day: today, in: window, calendar: calendar))
        var ended = fixtures.duration()
        ended.endedOn = TestCalendar.oct(5)
        #expect(!Editability.canLogTime(task: ended, day: today, in: window, calendar: calendar))
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

    // MARK: Correction window (SPEC §5.11, T-41)

    private func window(_ day: Int, _ hour: Int, _ minute: Int = 0, parts: PartSettings = .defaults) -> EditWindow {
        EditWindow(
            now: LocalTime(day: TestCalendar.oct(day), minute: hour * 60 + minute), parts: parts, calendar: calendar)
    }

    @Test func yesterdayIsCorrectableUntilAfternoonStarts() {
        // Wed 7 Oct at 11:59, Tue 6 Oct is CORRECTION; at 12:00 it's NONE.
        #expect(window(7, 11, 59).access(to: TestCalendar.oct(6)) == .correction)
        #expect(window(7, 12).access(to: TestCalendar.oct(6)) == .none)
        #expect(window(7, 0).access(to: TestCalendar.oct(6)) == .correction)
        // Mon 5 Oct is NONE all day Wednesday.
        for hour in [0, 9, 11, 12, 23] {
            #expect(window(7, hour).access(to: TestCalendar.oct(5)) == .none)
        }
        #expect(window(7, 9).access(to: TestCalendar.oct(7)) == .today)
        #expect(window(7, 9).access(to: TestCalendar.oct(8)) == .future)
    }

    @Test func theWindowMovesWithAfternoonsStart() {
        let late = PartSettings.defaults.setting(.noon, to: 780)
        #expect(window(7, 12, 59, parts: late).access(to: TestCalendar.oct(6)) == .correction)
        #expect(window(7, 13, parts: late).access(to: TestCalendar.oct(6)) == .none)
        #expect(window(7, 9, parts: late).closingMinute == 780)
        #expect(window(7, 13, parts: late).closingMinute == nil)
    }

    @Test func yesterdayCrossesMonthAndYearEnds() {
        let firstOfNovember = EditWindow(
            now: LocalTime(day: TestCalendar.oct(31).adding(days: 1, in: calendar), minute: 60), parts: .defaults,
            calendar: calendar)
        #expect(firstOfNovember.correctableDay == TestCalendar.oct(31))
    }

    @Test func correctionAllowsCompletingLoggingAndDeletingTime() throws {
        var fixtures = Fixtures()
        let oneTime = fixtures.oneTime(on: TestCalendar.oct(5))
        let progress = fixtures.habit()
        let duration = fixtures.duration()
        let open = EditWindow(today: today, correctableDay: TestCalendar.oct(5), closingMinute: 720)
        #expect(Editability.canComplete(try #require(fixtures.occurrence(oneTime, on: TestCalendar.oct(5))), in: open))
        #expect(Editability.canComplete(try #require(fixtures.occurrence(progress, on: TestCalendar.oct(5))), in: open))
        #expect(Editability.canLogTime(task: duration, day: TestCalendar.oct(5), in: open, calendar: calendar))
        let entry = TimeEntryValue(
            taskID: duration.id, day: TestCalendar.oct(5), seconds: 60, source: .manual,
            createdAt: TestCalendar.today(9))
        #expect(Editability.canDeleteTimeEntry(entry, in: open))
        // Moving and editing stay closed for yesterday.
        let pastOneTime = try #require(fixtures.occurrence(oneTime, on: TestCalendar.oct(5)))
        #expect(!Editability.canMove(pastOneTime, status: .missed, today: today))
        #expect(!Editability.canEditOneTime(oneTime, today: today))
        // The day before yesterday stays read-only.
        #expect(!Editability.canLogTime(task: duration, day: TestCalendar.oct(4), in: open, calendar: calendar))
    }

    @Test func aHabitWhoseLastDayWasYesterdayIsStillCorrectable() {
        var fixtures = Fixtures()
        var ended = fixtures.duration()
        ended.endedOn = TestCalendar.oct(5)
        let open = EditWindow(today: today, correctableDay: TestCalendar.oct(5), closingMinute: 720)
        #expect(Editability.canLogTime(task: ended, day: TestCalendar.oct(5), in: open, calendar: calendar))
        #expect(!Editability.canLogTime(task: ended, day: today, in: open, calendar: calendar))
    }
}
