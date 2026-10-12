import XCTest

/// SPEC T-09: the tabs, the buttons that open other screens, and every destination opened from a link.
final class NavigationUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testFourTabs() {
        let app = UITestApp.launch()
        // The Missed tab is called Not done in the Gentle style, the default (SPEC F-30).
        for name in ["Tasks", "Not done", "Stats", "Today"] {
            app.tabBars.buttons[name].tap()
            XCTAssertTrue(app.navigationBars[name].waitForExistence(timeout: 5), "\(name) didn't open")
        }
    }

    @MainActor
    func testGearOpensSettings() {
        let app = UITestApp.launch()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testClockOpensHistory() {
        let app = UITestApp.launch()
        app.tabBars.buttons["Tasks"].tap()
        app.buttons["History"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAddButtonOnTodayAndTasksOpensTheEditor() {
        let app = UITestApp.launch()
        app.buttons["Add task"].tap()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        app.tabBars.buttons["Tasks"].tap()
        app.buttons["Add task"].tap()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testNoAddButtonOnMissedOrStats() {
        let app = UITestApp.launch()
        app.tabBars.buttons["Not done"].tap()
        XCTAssertFalse(app.buttons["Add task"].exists)
        app.tabBars.buttons["Stats"].tap()
        XCTAssertFalse(app.buttons["Add task"].exists)
    }

    @MainActor
    func testLinksOpenEveryDestination() throws {
        let app = UITestApp.launch()
        app.open(try XCTUnwrap(URL(string: "tempo://missed")))
        XCTAssertTrue(app.navigationBars["Not done"].waitForExistence(timeout: 5))

        app.open(try XCTUnwrap(URL(string: "tempo://today?part=noon")))
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5))

        app.open(try XCTUnwrap(URL(string: "tempo://new?type=duration")))
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 5))

        app.open(try XCTUnwrap(URL(string: "tempo://timer")))
        XCTAssertTrue(app.staticTexts["No timer running"].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()

        app.open(try XCTUnwrap(URL(string: "tempo://unknown")))
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5))
    }
}
