import XCTest

/// SPEC T-28: the first-launch guide and Settings › How to use.
final class GuideUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testFirstLaunchGuide() {
        let app = UITestApp.launch(guide: true)
        XCTAssertTrue(app.staticTexts["Welcome to Tempo"].waitForExistence(timeout: 5))
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Three kinds of tasks"].waitForExistence(timeout: 3))
        app.swipeLeft()
        XCTAssertTrue(app.staticTexts["Reminders"].waitForExistence(timeout: 3))

        // Skip jumps to page 6, which has the part pickers and no Skip.
        app.buttons["Skip"].tap()
        XCTAssertTrue(app.staticTexts["Your parts of the day"].waitForExistence(timeout: 3))
        for part in ["Morning", "Noon", "Evening", "Night"] {
            XCTAssertTrue(app.datePickers[part].exists, "\(part) start is missing")
        }
        XCTAssertFalse(app.buttons["Skip"].exists)

        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Notifications"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Not now"].exists)
        app.buttons["Allow"].tap()

        // Then the empty Today screen (SPEC §6).
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Welcome to Tempo"].exists)
    }

    @MainActor
    func testOtherLaunchesSkipTheGuide() {
        let app = UITestApp.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Welcome to Tempo"].exists)
    }

    @MainActor
    func testHowToUseReopensPagesOneToFive() {
        let app = UITestApp.launch()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        let howToUse = app.buttons["How to use"]
        for _ in 0..<3 where !howToUse.isHittable { app.swipeUp() }
        howToUse.tap()

        XCTAssertTrue(app.staticTexts["Welcome to Tempo"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Skip"].exists)
        for _ in 0..<4 { app.buttons["Next"].tap() }
        XCTAssertTrue(app.staticTexts["Missed and Stats"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Next"].exists)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
    }
}
