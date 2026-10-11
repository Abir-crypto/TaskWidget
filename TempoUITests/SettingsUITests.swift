import XCTest

/// SPEC T-10: every setting is on the Settings screen.
final class SettingsUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// SPEC T-33: the eight presets and Custom, with the current choice marked.
    @MainActor
    func testThemeSwatches() {
        let app = UITestApp.launch()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        let blue = app.buttons["Blue"]
        for _ in 0..<4 where !blue.isHittable { app.swipeUp() }
        for name in ["Blue", "Indigo", "Purple", "Pink", "Red", "Orange", "Green", "Teal"] {
            XCTAssertTrue(app.buttons[name].exists, "\(name) is missing")
        }
        XCTAssertTrue(app.buttons["Custom"].exists)
        XCTAssertTrue(blue.isSelected)
        app.buttons["Purple"].tap()
        XCTAssertTrue(app.buttons["Purple"].waitForSelection())
        XCTAssertFalse(app.buttons["Blue"].isSelected)
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

extension XCUIElement {
    /// Waits briefly for the element to become selected.
    @MainActor
    fileprivate func waitForSelection(timeout: TimeInterval = 3) -> Bool {
        let selected = NSPredicate(format: "isSelected == true")
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: selected, object: self)], timeout: timeout)
            == .completed
    }
}
