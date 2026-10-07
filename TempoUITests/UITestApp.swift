import XCTest

/// Launches the app for UI tests with an in-memory store, so tests never touch real data.
@MainActor
enum UITestApp {
    /// - Parameters:
    ///   - now: an ISO 8601 moment to fix the app's clock at.
    ///   - sample: start with the sample tasks.
    ///   - missedPopup: let the missed popup appear; other tests keep it away.
    static func launch(now: String? = nil, sample: Bool = false, missedPopup: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-timezone", "Europe/London"]
        if let now { app.launchArguments += ["-ui-testing-now", now] }
        if sample { app.launchArguments.append("-ui-testing-sample") }
        if !missedPopup { app.launchArguments.append("-ui-testing-no-popup") }
        app.launch()
        return app
    }
}
