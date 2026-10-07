import Foundation
import Testing

@testable import Core

struct ScheduleEngineTests {
    private let calendar = TestCalendar.london

    @Test func oneTimeTaskOccursOnlyOnItsDate() {
        var fixtures = Fixtures()
        let task = fixtures.oneTime("Renew passport", on: TestCalendar.oct(8))
        let engine = fixtures.engine
        #expect(engine.occurrence(of: task, on: TestCalendar.oct(8)) != nil)
        #expect(engine.occurrence(of: task, on: TestCalendar.oct(7)) == nil)
        #expect(engine.occurrence(of: task, on: TestCalendar.oct(9)) == nil)
        #expect(
            engine.occurrences(from: TestCalendar.oct(1), through: TestCalendar.oct(31)).map(\.day) == [
                TestCalendar.oct(8)
            ])
    }

    @Test func monWedFriHabitOccursOnItsWeekdays() {
        var fixtures = Fixtures()
        let task = fixtures.habit(weekdays: [.monday, .wednesday, .friday])
        let engine = fixtures.engine
        #expect(engine.occurrence(of: task, on: TestCalendar.oct(5)) != nil)  // Mon
        #expect(engine.occurrence(of: task, on: TestCalendar.oct(7)) != nil)  // Wed
        #expect(engine.occurrence(of: task, on: TestCalendar.oct(6)) == nil)  // Tue
        let week = engine.occurrences(of: task, from: TestCalendar.oct(5), through: TestCalendar.oct(11))
        #expect(week.map(\.day) == [TestCalendar.oct(5), TestCalendar.oct(7), TestCalendar.oct(9)])
    }

    @Test func thirtyDayHabitEndsOnItsLastDay() {
        var fixtures = Fixtures()
        let task = fixtures.habit(start: TestCalendar.oct(1), length: 30)
        #expect(task.lastDay(in: calendar) == TestCalendar.oct(30))
        let engine = fixtures.engine
        #expect(engine.occurrence(of: task, on: TestCalendar.oct(30)) != nil)
        #expect(engine.occurrence(of: task, on: TestCalendar.oct(31)) == nil)
        #expect(engine.occurrences(of: task, from: TestCalendar.oct(1), through: TestCalendar.oct(31)).count == 30)
    }

    @Test func setLengthCountsCalendarDays() {
        // "Take medicine for 30 days on Mon, Wed and Fri" runs 30 calendar days, about 13 scheduled days.
        var fixtures = Fixtures()
        let task = fixtures.habit(weekdays: [.monday, .wednesday, .friday], start: TestCalendar.oct(1), length: 30)
        let days = fixtures.engine.occurrences(of: task, from: TestCalendar.oct(1), through: TestCalendar.oct(31))
        #expect(days.count == 13)
        #expect(days.last?.day == TestCalendar.oct(30))
    }

    @Test func endedHabitDoesNotOccurAfterItsEnd() {
        var fixtures = Fixtures()
        let task = fixtures.habit(start: TestCalendar.oct(1), endedOn: TestCalendar.oct(5))
        let engine = fixtures.engine
        #expect(task.lastDay(in: calendar) == TestCalendar.oct(5))
        #expect(engine.occurrence(of: task, on: TestCalendar.oct(5)) != nil)
        #expect(engine.occurrence(of: task, on: TestCalendar.oct(6)) == nil)
        #expect(task.hasEnded(today: TestCalendar.oct(6), calendar: calendar))
        #expect(!task.hasEnded(today: TestCalendar.oct(5), calendar: calendar))
    }

    @Test func lastDayIsTheEarlierOfLengthAndEndedOn() {
        var fixtures = Fixtures()
        let endedFirst = fixtures.habit(start: TestCalendar.oct(1), length: 30, endedOn: TestCalendar.oct(10))
        let lengthFirst = fixtures.habit(start: TestCalendar.oct(1), length: 5, endedOn: TestCalendar.oct(10))
        let ongoing = fixtures.habit(start: TestCalendar.oct(1))
        #expect(endedFirst.lastDay(in: calendar) == TestCalendar.oct(10))
        #expect(lengthFirst.lastDay(in: calendar) == TestCalendar.oct(5))
        #expect(ongoing.lastDay(in: calendar) == nil)
        #expect(!ongoing.hasEnded(today: DayKey(year: 2030, month: 1, day: 1), calendar: calendar))
    }

    @Test func habitsDoNotOccurBeforeTheirStart() {
        var fixtures = Fixtures()
        let task = fixtures.habit(start: TestCalendar.oct(8))
        let engine = fixtures.engine
        #expect(engine.occurrence(of: task, on: TestCalendar.oct(7)) == nil)
        #expect(engine.occurrence(of: task, on: TestCalendar.oct(8)) != nil)
    }

    @Test func weekdayChangeOnWednesdayKeepsEarlierDays() {
        // Every day until Tuesday, then only Thursday from Wednesday 7 Oct.
        var fixtures = Fixtures()
        let task = fixtures.habit(weekdays: .all, start: TestCalendar.oct(1))
        fixtures.reschedule(task, from: TestCalendar.oct(7), weekdays: [.thursday])
        let engine = fixtures.engine
        #expect(engine.occurrence(of: task, on: TestCalendar.oct(5)) != nil)  // Mon, old weekdays
        #expect(engine.occurrence(of: task, on: TestCalendar.oct(6)) != nil)  // Tue, old weekdays
        #expect(engine.occurrence(of: task, on: TestCalendar.oct(7)) == nil)  // Wed, new weekdays
        #expect(engine.occurrence(of: task, on: TestCalendar.oct(8)) != nil)  // Thu
        #expect(engine.schedule(for: task.id, on: TestCalendar.oct(6))?.weekdays == .all)
        #expect(engine.schedule(for: task.id, on: TestCalendar.oct(7))?.weekdays == [.thursday])
        #expect(engine.latestSchedule(for: task.id)?.weekdays == [.thursday])
    }

    @Test func scheduleIsTheLatestRowNotAfterTheDay() {
        var fixtures = Fixtures()
        let task = fixtures.duration(start: TestCalendar.oct(1), target: 30)
        fixtures.reschedule(task, from: TestCalendar.oct(5), target: 45)
        fixtures.reschedule(task, from: TestCalendar.oct(10), target: 60)
        let engine = fixtures.engine
        #expect(engine.schedule(for: task.id, on: TestCalendar.oct(4))?.targetMinutes == 30)
        #expect(engine.schedule(for: task.id, on: TestCalendar.oct(5))?.targetMinutes == 45)
        #expect(engine.schedule(for: task.id, on: TestCalendar.oct(9))?.targetMinutes == 45)
        #expect(engine.schedule(for: task.id, on: TestCalendar.oct(10))?.targetMinutes == 60)
        #expect(engine.schedule(for: task.id, on: TestCalendar.oct(30))?.targetMinutes == 60)
        #expect(engine.schedule(for: task.id, on: TestCalendar.oct(10))?.timing == .anytime)
    }

    @Test func deletedTasksNeverOccur() {
        var fixtures = Fixtures()
        let task = fixtures.habit()
        let oneTime = fixtures.oneTime()
        fixtures.delete(task)
        fixtures.delete(oneTime)
        let engine = fixtures.engine
        #expect(engine.occurrences(on: TestCalendar.today).isEmpty)
        #expect(engine.task(id: task.id) == nil)
    }

    @Test func deletedSchedulesAreIgnored() {
        var fixtures = Fixtures()
        let task = fixtures.habit(weekdays: .all)
        fixtures.reschedule(task, from: TestCalendar.oct(5), weekdays: [.friday])
        var data = fixtures.data
        if let index = data.schedules.firstIndex(where: { $0.effectiveFrom == TestCalendar.oct(5) }) {
            data.schedules[index].deletedAt = TestCalendar.today(9)
        }
        let engine = ScheduleEngine(data: data, calendar: calendar)
        #expect(engine.occurrence(of: task, on: TestCalendar.today) != nil)
    }

    @Test func occurrencesComeInCreationOrder() {
        var fixtures = Fixtures()
        let first = fixtures.habit("First")
        let second = fixtures.oneTime("Second")
        let third = fixtures.duration("Third")
        #expect(fixtures.engine.occurrences(on: TestCalendar.today).map(\.task.id) == [first.id, second.id, third.id])
    }

    @Test func occurrenceIDJoinsTaskAndDay() throws {
        var fixtures = Fixtures()
        let task = fixtures.oneTime()
        let occurrence = try #require(fixtures.engine.occurrence(of: task, on: TestCalendar.today))
        #expect(occurrence.id == "\(task.id.uuidString.lowercased())_20261006")
    }

    @Test func windowsAndPartsFollowTheTiming() throws {
        var fixtures = Fixtures()
        let fixed = fixtures.oneTime(timing: .fixed(minute: 750))
        let early = fixtures.oneTime(timing: .fixed(minute: 300))
        let part = fixtures.oneTime(timing: .part(.evening))
        let anytime = fixtures.oneTime(timing: .anytime)
        let engine = fixtures.engine
        let parts = PartSettings.defaults
        let fixedOccurrence = try #require(engine.occurrence(of: fixed, on: TestCalendar.today))
        #expect(fixedOccurrence.window(parts: parts) == 720..<1020)
        #expect(fixedOccurrence.part(parts: parts) == .noon)
        let earlyOccurrence = try #require(engine.occurrence(of: early, on: TestCalendar.today))
        #expect(earlyOccurrence.part(parts: parts) == .morning)
        #expect(earlyOccurrence.window(parts: parts) == 360..<720)
        #expect(engine.occurrence(of: part, on: TestCalendar.today)?.window(parts: parts) == 1020..<1260)
        #expect(engine.occurrence(of: anytime, on: TestCalendar.today)?.window(parts: parts) == 0..<1440)
        #expect(engine.occurrence(of: anytime, on: TestCalendar.today)?.part(parts: parts) == nil)
    }

    @Test func liveDaysIncludeUnscheduledOnes() {
        var fixtures = Fixtures()
        let task = fixtures.duration(weekdays: [.monday], start: TestCalendar.oct(1))
        let engine = fixtures.engine
        #expect(engine.isLive(task, on: TestCalendar.today))  // Tuesday, not scheduled
        #expect(engine.occurrence(of: task, on: TestCalendar.today) == nil)
        #expect(!engine.isLive(task, on: DayKey(year: 2026, month: 9, day: 30)))
    }
}
