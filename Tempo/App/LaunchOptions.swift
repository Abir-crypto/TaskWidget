import Foundation

/// Launch arguments used by UI tests, so they never touch the real store.
///
/// - `-ui-testing`: an in-memory store and separate device-only state.
/// - `-ui-testing-now <ISO 8601 date>`: a clock fixed at that moment.
/// - `-ui-testing-timezone <identifier>`: the time zone rules run in, so fixed times mean the same on any Mac.
/// - `-ui-testing-sample`: start with `SampleData`.
/// - `-ui-testing-no-popup`: mark today's missed tasks as already seen, so the missed popup stays away.
struct LaunchOptions {
    var isUITesting = false
    var fixedNow: Date?
    var timeZone: TimeZone?
    var usesSampleData = false
    var suppressesMissedPopup = false

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        isUITesting = arguments.contains("-ui-testing")
        usesSampleData = arguments.contains("-ui-testing-sample")
        suppressesMissedPopup = arguments.contains("-ui-testing-no-popup")
        fixedNow = value(after: "-ui-testing-now", in: arguments).flatMap { ISO8601DateFormatter().date(from: $0) }
        timeZone = value(after: "-ui-testing-timezone", in: arguments).flatMap(TimeZone.init(identifier:))
    }

    /// The calendar for UI tests: the user's, in the requested time zone.
    var calendar: Calendar {
        var calendar = Calendar.autoupdatingCurrent
        if let timeZone { calendar.timeZone = timeZone }
        return calendar
    }

    private func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
}
