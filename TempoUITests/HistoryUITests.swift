import XCTest

/// SPEC T-14: History's segments, search and empty states.
final class HistoryUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testEmptyStates() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00")
        app.tabBars.buttons["Tasks"].tap()
        app.buttons["History"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Nothing completed yet"].waitForExistence(timeout: 3))
        app.buttons["Habits"].tap()
        XCTAssertTrue(app.staticTexts["Finished habits will appear here"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testEndedHabitShowsItsResultAndStartsAgain() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        app.tabBars.buttons["Tasks"].tap()
        app.buttons["History"].tap()
        app.buttons["Habits"].tap()
        XCTAssertTrue(app.staticTexts["Meditate"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Done 26 of 30 days"].exists)
        app.buttons["Start again"].tap()
        XCTAssertTrue(app.alerts["Started again"].waitForExistence(timeout: 3))
        app.alerts.buttons["OK"].tap()
        // Back in Tasks, the restarted habit is active again.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Habits"].tap()
        XCTAssertTrue(app.staticTexts["Meditate"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testCompletedTaskAppearsAndCanBeUndone() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        let checkbox = app.buttons.matching(NSPredicate(format: "label == 'Mark done' AND value == 'Call the bank'"))
            .firstMatch
        XCTAssertTrue(checkbox.waitForExistence(timeout: 5))
        checkbox.tap()
        app.tabBars.buttons["Tasks"].tap()
        app.buttons["History"].tap()
        app.buttons["One-time"].tap()
        XCTAssertTrue(app.staticTexts["Call the bank"].waitForExistence(timeout: 3))
        let search = app.searchFields.firstMatch
        if search.exists {
            search.tap()
            search.typeText("zzz")
            XCTAssertTrue(app.staticTexts["No matches"].waitForExistence(timeout: 3))
            search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3))
        }
        let undo = app.buttons.matching(NSPredicate(format: "label == 'Mark not done' AND value == 'Call the bank'"))
            .firstMatch
        XCTAssertTrue(undo.waitForExistence(timeout: 3))
        undo.tap()
        XCTAssertTrue(app.staticTexts["Nothing completed yet"].waitForExistence(timeout: 3))
    }
}
