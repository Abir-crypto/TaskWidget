import Core
import Foundation
import SwiftData

@testable import Tempo

/// Shared fixtures for app tests: the fixed calendar and clock from ios.md §13, and in-memory stores.
enum TestEnvironment {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London") ?? .gmt
        calendar.locale = Locale(identifier: "en_GB")
        calendar.firstWeekday = 2
        return calendar
    }()

    /// Tuesday 6 Oct 2026, the reference "today" (SPEC §8).
    static let today = DayKey(year: 2026, month: 10, day: 6)

    /// A moment on the London wall clock.
    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        DayKey(year: year, month: month, day: day).date(atMinute: hour * 60 + minute, in: calendar)
    }

    /// A clock at a time on Tuesday 6 Oct 2026.
    static func clock(hour: Int = 12, minute: Int = 0) -> FixedClock {
        FixedClock(date(2026, 10, 6, hour, minute), calendar: calendar)
    }

    /// A fresh in-memory store.
    static func store(clock: any Clock) throws -> SwiftDataTaskStore {
        SwiftDataTaskStore(container: try StoreFactory.make(inMemory: true), clock: clock)
    }

    /// Device-only state in its own `UserDefaults` suite, so tests don't share it.
    static func deviceState(suite: String = "tests.\(UUID().uuidString)") -> DeviceState {
        DeviceState(defaults: UserDefaults(suiteName: suite) ?? .standard)
    }
}
