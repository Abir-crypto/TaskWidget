import XCTest

/// SPEC T-15: Habit detail opens from Today and Tasks, and its buttons work.
final class HabitDetailUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testOpensFromTodayWithItsSections() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        let read = app.staticTexts["Read"]
        XCTAssertTrue(read.waitForExistence(timeout: 5))
        read.tap()
        XCTAssertTrue(app.staticTexts["This week"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Log time"].exists)
        XCTAssertTrue(app.buttons["End habit"].exists)
        XCTAssertTrue(app.buttons["Edit"].exists)
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Stats"].waitForExistence(timeout: 3))
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Today's time"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testEndHabitConfirmsFirst() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        app.tabBars.buttons["Tasks"].tap()
        app.buttons["Habits"].tap()
        app.staticTexts["Gym"].tap()
        let end = app.buttons["End habit"]
        XCTAssertTrue(end.waitForExistence(timeout: 3))
        end.tap()
        XCTAssertTrue(app.staticTexts["End this habit?"].waitForExistence(timeout: 3))
        app.buttons["End habit"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Start again"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testSeeAllOpensTheMissedTab() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        app.tabBars.buttons["Tasks"].tap()
        app.buttons["Habits"].tap()
        app.staticTexts["Take medicine"].tap()
        let seeAll = app.buttons["See all"]
        for _ in 0..<4 where !seeAll.isHittable { app.swipeUp() }
        seeAll.tap()
        XCTAssertTrue(app.navigationBars["Not done"].waitForExistence(timeout: 3))
    }
}
