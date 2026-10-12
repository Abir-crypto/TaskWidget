import XCTest

/// SPEC T-16: the Missed tab's sections, actions and filters.
final class MissedUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// In the Strict style, with its 1.0 wording.
    @MainActor
    func testTodayActionsAndEarlierFilters() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true, strict: true)
        app.tabBars.buttons["Missed"].tap()
        XCTAssertTrue(app.staticTexts["Stretch"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["You can still change these"].exists)
        app.buttons["Mark done"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["You haven't missed a task today"].waitForExistence(timeout: 3))

        // Earlier: filter to a part with nothing in it, then clear.
        app.buttons["Sort and filter"].tap()
        XCTAssertTrue(app.navigationBars["Sort & filter"].waitForExistence(timeout: 3))
        for part in ["Morning", "Evening", "Night", "Anytime"] {
            let toggle = app.switches[part]
            for _ in 0..<3 where !toggle.isHittable { app.swipeUp() }
            // Tap the switch itself; tapping the row's label doesn't flip it.
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        }
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["No missed tasks match these filters"].waitForExistence(timeout: 3))
        app.buttons["Clear filters"].firstMatch.tap()
        XCTAssertFalse(app.staticTexts["No missed tasks match these filters"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testEmptyStates() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", strict: true)
        app.tabBars.buttons["Missed"].tap()
        XCTAssertTrue(app.staticTexts["You haven't missed a task today"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Nothing missed before today"].exists)
    }

    /// SPEC T-40: the Gentle style (the default) calls the tab Not done, has no badge, and says "not done".
    @MainActor
    func testGentleStyleWording() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        let tab = app.tabBars.buttons["Not done"]
        XCTAssertTrue(tab.waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.buttons["Missed"].exists)
        XCTAssertEqual(tab.value as? String ?? "", "")
        tab.tap()
        XCTAssertTrue(app.navigationBars["Not done"].waitForExistence(timeout: 3))
        let notDone = NSPredicate(format: "label CONTAINS 'Not done'")
        XCTAssertTrue(app.descendants(matching: .any).matching(notDone).firstMatch.exists)
        app.buttons["Mark done"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Nothing left undone today"].waitForExistence(timeout: 3))
    }
}
