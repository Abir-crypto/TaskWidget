import XCTest

/// SPEC T-12: the Today screen's rows, swipe actions, day strip and Log time.
final class TodayUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testCheckboxCompletesAndUndoes() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        let checkbox = app.buttons.matching(NSPredicate(format: "label == 'Mark done' AND value == 'Call the bank'"))
            .firstMatch
        XCTAssertTrue(checkbox.waitForExistence(timeout: 5))
        checkbox.tap()
        let undo = app.buttons.matching(NSPredicate(format: "label == 'Mark not done' AND value == 'Call the bank'"))
            .firstMatch
        XCTAssertTrue(undo.waitForExistence(timeout: 3))
        undo.tap()
        XCTAssertTrue(checkbox.waitForExistence(timeout: 3))
    }

    @MainActor
    func testLogTimeFromASwipe() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        let read = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Read'")).firstMatch
        XCTAssertTrue(read.waitForExistence(timeout: 5))
        read.swipeRight()
        app.buttons["Log time"].tap()
        let add = app.buttons["Add"]
        XCTAssertTrue(add.waitForExistence(timeout: 3))
        add.tap()
        XCTAssertTrue(app.staticTexts["30 of 30 min"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testMoveToTomorrowFromASwipe() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        let call = app.staticTexts["Call the bank"]
        XCTAssertTrue(call.waitForExistence(timeout: 5))
        call.swipeLeft()
        app.buttons["Move to tomorrow"].tap()
        XCTAssertTrue(call.waitForNonExistence(timeout: 3))
        app.buttons["day-20261007"].tap()
        XCTAssertTrue(app.staticTexts["Call the bank"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testDayStripSwipesByAWeekAndTodayReturns() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        XCTAssertTrue(app.buttons["day-20261006"].waitForExistence(timeout: 5))
        // Drag across the strip, from Friday to Sunday.
        let from = app.buttons["day-20261009"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let to = app.buttons["day-20261004"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        from.press(forDuration: 0.05, thenDragTo: to)
        XCTAssertTrue(app.buttons["day-20261013"].waitForExistence(timeout: 3))
        app.navigationBars.buttons["Today"].tap()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testEndedPartExpandsAndPastDaysAreReadOnly() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        let morning = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Morning'")).firstMatch
        XCTAssertTrue(morning.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Stretch"].exists)
        morning.tap()
        XCTAssertTrue(app.staticTexts["Stretch"].waitForExistence(timeout: 3))
        app.buttons["day-20261005"].tap()
        let pastCheckbox = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Mark'")).firstMatch
        XCTAssertTrue(pastCheckbox.waitForExistence(timeout: 3))
        XCTAssertFalse(pastCheckbox.isEnabled)
    }
}
