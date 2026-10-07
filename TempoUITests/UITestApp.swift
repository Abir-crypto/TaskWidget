import XCTest

/// Launches the app for UI tests with an in-memory store, so tests never touch real data.
@MainActor
enum UITestApp {
    /// - Parameter now: an ISO 8601 moment to fix the app's clock at.
    static func launch(now: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        if let now { app.launchArguments += ["-ui-testing-now", now] }
        app.launch()
        return app
    }
}
