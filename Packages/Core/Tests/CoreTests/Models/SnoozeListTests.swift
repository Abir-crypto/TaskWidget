import Foundation
import Testing

@testable import Core

/// SPEC §4.6: snoozes are kept for their day only.
struct SnoozeListTests {
    private let today = TestCalendar.today
    private let tomorrow = TestCalendar.oct(7)

    private func snooze() -> Snooze {
        Snooze(
            originalID: "ending-soon.20261006.evening", kind: .endingSoon,
            fireDate: TestCalendar.today(20, 45), day: today)
    }

    @Test func snoozesApplyOnTheirDay() {
        let list = SnoozeList(day: today, snoozes: [snooze()])
        #expect(list.snoozes(on: today) == [snooze()])
    }

    @Test func snoozesClearWhenTheDayChanges() {
        let list = SnoozeList(day: today, snoozes: [snooze()])
        #expect(list.snoozes(on: tomorrow).isEmpty)
    }

    @Test func kindsAreStoredAsFixedStrings() throws {
        let encoded = try JSONEncoder().encode([SnoozeKind.fixed, .endingSoon])
        #expect(String(decoding: encoded, as: UTF8.self) == #"["fixed","ending_soon"]"#)
    }
}
