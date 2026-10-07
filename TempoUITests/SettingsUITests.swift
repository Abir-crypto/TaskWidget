import XCTest

/// SPEC T-10: every setting is on the Settings screen.
final class SettingsUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testEverySettingIsPresent() {
        let app = UITestApp.launch()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        for part in ["Morning", "Noon", "Evening", "Night"] {
            XCTAssertTrue(app.staticTexts[part].exists, "\(part) start is missing")
        }
        for toggle in ["Part starts", "Ending soon", "Fixed-time tasks", "End-of-day recap", "Running timer alert"] {
            XCTAssertTrue(app.switches[toggle].exists, "\(toggle) is missing")
        }
        XCTAssertTrue(app.staticTexts["Before the part ends"].exists)
        XCTAssertTrue(app.staticTexts["Before the task"].exists)
        XCTAssertTrue(app.staticTexts["Recap time"].exists)
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Alert after"].exists)
        XCTAssertTrue(app.staticTexts["Notifications"].exists)
        XCTAssertTrue(app.switches["Hide task names on the Lock Screen"].exists)
        XCTAssertTrue(app.staticTexts["Version"].exists)
    }

}
