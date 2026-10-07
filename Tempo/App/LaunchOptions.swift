import Foundation

/// Launch arguments used by UI tests, so they never touch the real store.
///
/// - `-ui-testing`: an in-memory store and separate device-only state.
/// - `-ui-testing-now <ISO 8601 date>`: a clock fixed at that moment.
struct LaunchOptions {
    var isUITesting = false
    var fixedNow: Date?

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        isUITesting = arguments.contains("-ui-testing")
        if let index = arguments.firstIndex(of: "-ui-testing-now"), arguments.indices.contains(index + 1) {
            fixedNow = ISO8601DateFormatter().date(from: arguments[index + 1])
        }
    }
}
