import XCTest

/// SPEC T-20: ▶, the timer bar, the timer screen, the task picker and the confirmation.
final class TimerUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testPlayStartsATimerAndHidesEveryPlay() {
        let app = UITestApp.launch(now: "2026-10-06T18:00:00+01:00", sample: true)
        let play = app.buttons["Start timer"]
        XCTAssertTrue(play.waitForExistence(timeout: 5))
        play.tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Done"].exists)
        XCTAssertFalse(app.buttons["Start timer"].exists)

        // The bar is on every tab.
        app.tabBars.buttons["Stats"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 3))

        // Tapping the bar opens the timer screen, with the habit's progress including earlier time.
        app.staticTexts["Read"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["10 of 30 min today"].waitForExistence(timeout: 3))
        app.buttons["timer-screen-pause"].tap()
        XCTAssertTrue(app.staticTexts["Paused"].waitForExistence(timeout: 3))
        app.buttons["timer-screen-done"].tap()
        // The clock is fixed in UI tests, so no time passed: nothing is saved.
        XCTAssertTrue(app.staticTexts["Less than a minute, nothing saved."].waitForExistence(timeout: 3))
    }

    @MainActor
    func testFinishedGenericTimerOpensThePicker() {
        let app = UITestApp.launch(now: "2026-10-06T18:00:00+01:00", sample: true, finishedTimer: 1_080)
        XCTAssertTrue(app.staticTexts["Add 18 min to"].waitForExistence(timeout: 5))
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Read'")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Added 18 min to Read · 28 of 30 min today"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Change task"].exists)
        app.buttons["Undo"].tap()
        XCTAssertFalse(app.buttons["Undo"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testPickerEmptyState() {
        let app = UITestApp.launch(now: "2026-10-06T18:00:00+01:00", finishedTimer: 600)
        XCTAssertTrue(app.staticTexts["No duration tasks yet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Add a duration task"].exists)
        app.buttons["Discard"].firstMatch.tap()
        XCTAssertFalse(app.staticTexts["No duration tasks yet"].waitForExistence(timeout: 2))
    }
}
