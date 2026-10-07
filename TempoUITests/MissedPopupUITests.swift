import XCTest

/// SPEC T-17: when the missed popup shows, what its buttons do, and that each task shows only once.
final class MissedPopupUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testNormalOpenShowsThePopupOnce() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true, missedPopup: true)
        XCTAssertTrue(app.staticTexts["You missed 1 task today"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Stretch"].exists)
        app.buttons["Not now"].tap()
        XCTAssertFalse(app.staticTexts["You missed 1 task today"].waitForExistence(timeout: 2))

        // Going to the background and back is a normal open; the task has been seen, so no popup.
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertFalse(app.staticTexts["You missed 1 task today"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testReviewOpensTheMissedTab() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true, missedPopup: true)
        let review = app.buttons["Review missed tasks"]
        XCTAssertTrue(review.waitForExistence(timeout: 5))
        review.tap()
        XCTAssertTrue(app.navigationBars["Missed"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["You can still change these"].exists)
    }
}
