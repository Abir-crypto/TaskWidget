import XCTest

/// Saves screenshots of screens for visual review. Skipped unless `TEMPO_SCREENSHOTS` names a folder; pass it
/// to `xcodebuild` as `TEST_RUNNER_TEMPO_SCREENSHOTS=<folder>`.
final class ScreenshotTests: XCTestCase {
    private var folder: URL?

    override func setUpWithError() throws {
        let path = ProcessInfo.processInfo.environment["TEMPO_SCREENSHOTS"]
        try XCTSkipIf(path == nil, "Set TEMPO_SCREENSHOTS to save screenshots")
        folder = path.map { URL(filePath: $0) }
        continueAfterFailure = true
    }

    @MainActor
    private func save(_ app: XCUIApplication, _ name: String) {
        guard let folder else { return }
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? app.screenshot().pngRepresentation.write(to: folder.appending(path: "\(name).png"))
    }

    @MainActor
    func testSettings() {
        let app = UITestApp.launch(now: "2026-10-06T10:30:00+01:00")
        app.buttons["Settings"].tap()
        _ = app.navigationBars["Settings"].waitForExistence(timeout: 5)
        save(app, "settings-1")
        app.swipeUp()
        save(app, "settings-2")
    }

    @MainActor
    func testEditor() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00")
        app.buttons["Add task"].tap()
        _ = app.buttons["Save"].waitForExistence(timeout: 5)
        save(app, "editor-1-new")
        app.buttons["Duration"].tap()
        app.buttons["Fixed time"].tap()
        save(app, "editor-2-duration")
        app.swipeUp()
        save(app, "editor-3-duration-scrolled")
    }

    @MainActor
    func testToday() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        _ = app.navigationBars["Today"].waitForExistence(timeout: 5)
        save(app, "today-1")
        app.swipeUp()
        save(app, "today-2-scrolled")
        app.swipeDown()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Morning'")).firstMatch.tap()
        save(app, "today-3-morning-expanded")
        app.buttons["day-20261008"].tap()
        save(app, "today-4-thursday")
        app.buttons["day-20261005"].tap()
        save(app, "today-5-monday")
    }

    @MainActor
    func testTodayEmpty() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00")
        _ = app.navigationBars["Today"].waitForExistence(timeout: 5)
        save(app, "today-empty")
    }

    @MainActor
    func testTasks() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        app.tabBars.buttons["Tasks"].tap()
        app.buttons["Habits"].tap()
        _ = app.staticTexts["Take medicine"].waitForExistence(timeout: 5)
        save(app, "tasks-habits")
        app.buttons["One-time"].tap()
        save(app, "tasks-onetime")
    }

    @MainActor
    func testHistory() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        app.tabBars.buttons["Tasks"].tap()
        app.buttons["History"].tap()
        app.buttons["Habits"].tap()
        _ = app.staticTexts["Meditate"].waitForExistence(timeout: 5)
        save(app, "history-habits")
    }

    @MainActor
    func testHabitDetail() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Read'")).firstMatch.tap()
        _ = app.staticTexts["This week"].waitForExistence(timeout: 5)
        save(app, "habit-1")
        app.swipeUp()
        save(app, "habit-2")
        app.swipeUp()
        save(app, "habit-3")
    }
}
