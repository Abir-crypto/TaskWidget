import XCTest

/// SPEC T-18: the Stats screen's ranges, limits, chart taps and empty state.
final class StatsUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testEmptyState() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00")
        app.tabBars.buttons["Stats"].tap()
        XCTAssertTrue(app.staticTexts["Add a habit to see your stats"].waitForExistence(timeout: 5))
        app.buttons["Add a habit"].tap()
        XCTAssertTrue(app.buttons["Progress"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testRangesAndTappingADay() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        app.tabBars.buttons["Stats"].tap()
        XCTAssertTrue(app.staticTexts["Overview"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Next"].isEnabled)
        XCTAssertTrue(app.buttons["Previous"].isEnabled)
        app.buttons["Month"].tap()
        let monday = app.buttons["stats-day-20261005"]
        XCTAssertTrue(monday.waitForExistence(timeout: 3))
        monday.tap()
        XCTAssertTrue(app.navigationBars["Yesterday"].waitForExistence(timeout: 3))
    }
}
