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
}
