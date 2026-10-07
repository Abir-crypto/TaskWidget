import XCTest

/// SPEC T-13: the Tasks tab's segments, the remembered choice and the + preset.
final class TasksUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testSegmentIsRememberedAfterARestart() {
        var app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        app.tabBars.buttons["Tasks"].tap()
        app.buttons["One-time"].tap()
        XCTAssertTrue(app.staticTexts["Pick up the parcel"].waitForExistence(timeout: 3))
        app.terminate()

        app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        app.tabBars.buttons["Tasks"].tap()
        XCTAssertTrue(app.staticTexts["Pick up the parcel"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["One-time"].isSelected)

        app.buttons["Habits"].tap()
        XCTAssertTrue(app.staticTexts["Take medicine"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testAddPresetsTheTypeFromTheSegment() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00")
        app.tabBars.buttons["Tasks"].tap()
        app.buttons["Habits"].tap()
        XCTAssertTrue(app.staticTexts["No habits yet"].waitForExistence(timeout: 3))
        app.buttons["Add task"].tap()
        XCTAssertTrue(app.buttons["Progress"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Progress"].isSelected)
        app.buttons["Cancel"].tap()
        app.buttons["One-time"].tap()
        XCTAssertTrue(app.staticTexts["No upcoming tasks"].waitForExistence(timeout: 3))
        app.buttons["Add task"].tap()
        XCTAssertTrue(app.buttons["One-time"].firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(app.sheets.firstMatch.exists || app.buttons["Cancel"].exists)
    }
}
