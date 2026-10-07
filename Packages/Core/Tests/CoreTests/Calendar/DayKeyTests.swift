import Foundation
import Testing

@testable import Core

struct DayKeyTests {
    private let calendar = TestCalendar.london

    private func utc(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        return utc.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))
            ?? .distantPast
    }

    @Test func rawValueAndComponents() {
        let day = DayKey(year: 2026, month: 10, day: 6)
        #expect(day.rawValue == 20_261_006)
        #expect(day.year == 2026)
        #expect(day.month == 10)
        #expect(day.day == 6)
        #expect(day.description == "20261006")
    }

    @Test func convertsToDateAndBack() {
        let day = TestCalendar.today
        let start = day.startDate(in: calendar)
        #expect(start == utc(2026, 10, 5, 23, 0))  // midnight BST
        #expect(DayKey(start, calendar: calendar) == day)
        #expect(DayKey(start.addingTimeInterval(86_399), calendar: calendar) == day)
        #expect(DayKey(start.addingTimeInterval(86_400), calendar: calendar) == day.adding(days: 1, in: calendar))
    }

    private static let additions: [(start: Int, days: Int, expected: Int)] = [
        (20_261_031, 1, 20_261_101),  // month end
        (20_261_231, 1, 20_270_101),  // year end
        (20_270_101, -1, 20_261_231),
        (20_280_228, 1, 20_280_229),  // leap day
        (20_260_228, 1, 20_260_301),
        (20_260_328, 1, 20_260_329),  // into the spring-forward day
        (20_260_329, 1, 20_260_330),  // out of the 23-hour day
        (20_261_025, 1, 20_261_026),  // out of the 25-hour day
        (20_261_026, -1, 20_261_025),
        (20_261_006, 30, 20_261_105),
        (20_261_006, -365, 20_251_006),
    ]

    @Test(arguments: additions)
    func addsDaysThroughTheCalendar(start: Int, days: Int, expected: Int) {
        #expect(DayKey(rawValue: start).adding(days: days, in: calendar) == DayKey(rawValue: expected))
    }

    @Test func countsDaysAcrossDaylightSaving() {
        let before = DayKey(year: 2026, month: 3, day: 28)
        let after = DayKey(year: 2026, month: 3, day: 30)
        #expect(before.days(to: after, in: calendar) == 2)
        #expect(after.days(to: before, in: calendar) == -2)
        #expect(TestCalendar.oct(24).days(to: TestCalendar.oct(26), in: calendar) == 2)
        #expect(TestCalendar.oct(1).days(to: TestCalendar.oct(30), in: calendar) == 29)
    }

    @Test func weekdayAndWeek() {
        #expect(TestCalendar.today.weekday(in: calendar) == .tuesday)
        #expect(TestCalendar.oct(5).weekday(in: calendar) == .monday)
        #expect(TestCalendar.oct(11).weekday(in: calendar) == .sunday)
        #expect(TestCalendar.today.startOfWeek(in: calendar) == TestCalendar.oct(5))
        #expect(TestCalendar.oct(11).startOfWeek(in: calendar) == TestCalendar.oct(5))
        #expect(TestCalendar.today.week(in: calendar) == (5...11).map { TestCalendar.oct($0) })
    }

    @Test func weekStartFollowsTheRegion() {
        var sundayFirst = calendar
        sundayFirst.firstWeekday = 1
        #expect(TestCalendar.today.startOfWeek(in: sundayFirst) == TestCalendar.oct(4))
        #expect(TestCalendar.oct(4).startOfWeek(in: sundayFirst) == TestCalendar.oct(4))
    }

    @Test func monthAndYearStarts() {
        #expect(TestCalendar.today.startOfMonth == TestCalendar.oct(1))
        #expect(TestCalendar.today.startOfYear == DayKey(year: 2026, month: 1, day: 1))
    }

    @Test func throughListsEveryDay() {
        let days = DayKey(year: 2026, month: 10, day: 30).through(DayKey(year: 2026, month: 11, day: 2), in: calendar)
        #expect(days.map(\.rawValue) == [20_261_030, 20_261_031, 20_261_101, 20_261_102])
        #expect(TestCalendar.oct(6).through(TestCalendar.oct(5), in: calendar).isEmpty)
    }

    @Test func minuteOfDayBecomesALocalMoment() {
        #expect(TestCalendar.today.date(atMinute: 750, in: calendar) == utc(2026, 10, 6, 11, 30))
        #expect(TestCalendar.today.date(atMinute: 0, in: calendar) == TestCalendar.today.startDate(in: calendar))
    }

    @Test func midnightIsTheStartOfTheNextDay() {
        let midnight = TestCalendar.today.date(atMinute: 1440, in: calendar)
        #expect(midnight == TestCalendar.oct(7).startDate(in: calendar))
    }

    @Test func gapTimeUsesTheNextValidMoment() {
        // 29 Mar 2026: London clocks jump from 01:00 GMT to 02:00 BST, so 01:30 doesn't exist.
        let gapDay = DayKey(year: 2026, month: 3, day: 29)
        #expect(gapDay.date(atMinute: 90, in: calendar) == utc(2026, 3, 29, 1, 0))  // 02:00 BST
        #expect(gapDay.date(atMinute: 150, in: calendar) == utc(2026, 3, 29, 1, 30))  // 02:30 BST
        #expect(gapDay.date(atMinute: 30, in: calendar) == utc(2026, 3, 29, 0, 30))  // 00:30 GMT
    }

    @Test func repeatedTimeUsesTheFirstMoment() {
        // 25 Oct 2026: London clocks go back from 02:00 BST to 01:00 GMT, so 01:30 happens twice.
        let overlapDay = DayKey(year: 2026, month: 10, day: 25)
        #expect(overlapDay.date(atMinute: 90, in: calendar) == utc(2026, 10, 25, 0, 30))  // 01:30 BST
        #expect(overlapDay.date(atMinute: 180, in: calendar) == utc(2026, 10, 25, 3, 0))  // 03:00 GMT
    }

    @Test func validity() {
        #expect(TestCalendar.today.isValid(in: calendar))
        #expect(DayKey(year: 2028, month: 2, day: 29).isValid(in: calendar))
        #expect(!DayKey(year: 2026, month: 2, day: 29).isValid(in: calendar))
        #expect(!DayKey(year: 2026, month: 13, day: 1).isValid(in: calendar))
        #expect(!DayKey.distantPast.isValid(in: calendar))
    }

    @Test func comparesChronologically() {
        #expect(TestCalendar.oct(5) < TestCalendar.oct(6))
        #expect(DayKey(year: 2026, month: 12, day: 31) < DayKey(year: 2027, month: 1, day: 1))
        #expect(DayKey.distantPast < TestCalendar.oct(1))
    }

    @Test func encodesAsAPlainInteger() throws {
        let data = try JSONEncoder().encode(TestCalendar.today)
        #expect(String(decoding: data, as: UTF8.self) == "20261006")
        #expect(try JSONDecoder().decode(DayKey.self, from: data) == TestCalendar.today)
    }

    @Test func localTimeReadsTheWallClock() {
        let time = LocalTime(TestCalendar.today(16, 59), calendar: calendar)
        #expect(time.day == TestCalendar.today)
        #expect(time.minute == 16 * 60 + 59)
        #expect(time.date(in: calendar) == TestCalendar.today(16, 59))

        let lateNight = LocalTime(TestCalendar.today(23, 59), calendar: calendar)
        #expect(lateNight.minute == 1439)
        #expect(
            LocalTime(TestCalendar.today(23, 59).addingTimeInterval(60), calendar: calendar).day == TestCalendar.oct(7))
    }
}
