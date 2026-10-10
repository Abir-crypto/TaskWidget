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
        // The form is longer than the screen, so scroll down to each item in turn.
        let items = [
            app.switches["Part starts"], app.switches["Ending soon"], app.staticTexts["Before the part ends"],
            app.switches["Fixed-time tasks"], app.staticTexts["Before the task"], app.switches["End-of-day recap"],
            app.staticTexts["Recap time"], app.switches["Running timer alert"], app.staticTexts["Alert after"],
            app.staticTexts["Notifications"], app.switches["Hide task names on the Lock Screen"],
            app.buttons["How to use"], app.staticTexts["Version"],
        ]
        for item in items {
            for _ in 0..<4 where !item.exists { app.swipeUp() }
            XCTAssertTrue(item.exists, "\(item) is missing")
        }
    }

}
