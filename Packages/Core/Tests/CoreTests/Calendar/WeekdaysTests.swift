import Testing

@testable import Core

struct WeekdaysTests {
    @Test func monWedFriIs21() {
        #expect(Weekdays([.monday, .wednesday, .friday]).rawValue == 21)
        #expect(Weekdays([.monday, .wednesday, .friday]) == [.monday, .wednesday, .friday])
    }

    @Test func everyDayIs127() {
        #expect(Weekdays.all.rawValue == 127)
        #expect(Weekdays(Weekday.allCases) == .all)
        #expect(Weekdays.none.rawValue == 0)
    }

    @Test func bitsMatchTheSpec() {
        let bits = Weekday.allCases.map(\.bit.rawValue)
        #expect(bits == [1, 2, 4, 8, 16, 32, 64])
    }

    @Test func containsAndLists() {
        let days = Weekdays([.friday, .monday])
        #expect(days.contains(.monday))
        #expect(!days.contains(.tuesday))
        #expect(days.days == [.monday, .friday])
    }

    @Test func convertsCalendarWeekdayNumbers() {
        // Calendar numbers weekdays 1 (Sunday) to 7 (Saturday).
        #expect(Weekday(calendarWeekday: 1) == .sunday)
        #expect(Weekday(calendarWeekday: 2) == .monday)
        #expect(Weekday(calendarWeekday: 7) == .saturday)
        #expect(Weekday(calendarWeekday: 0) == nil)
        #expect(Weekday(calendarWeekday: 8) == nil)
        for day in Weekday.allCases {
            #expect(Weekday(calendarWeekday: day.calendarWeekday) == day)
        }
    }

    @Test func ordersFromTheRegionsFirstWeekday() {
        #expect(Weekday.ordered(firstWeekday: 2).first == .monday)
        #expect(Weekday.ordered(firstWeekday: 2).last == .sunday)
        #expect(
            Weekday.ordered(firstWeekday: 1) == [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday])
        #expect(Weekday.ordered(firstWeekday: 7).first == .saturday)
    }
}
