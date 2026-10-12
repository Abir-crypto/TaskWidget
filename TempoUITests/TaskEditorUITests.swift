import XCTest

/// SPEC T-11: creating tasks in the editor, and its validation.
final class TaskEditorUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testCreatesAOneTimeTask() {
        let app = UITestApp.launch(now: "2026-10-06T10:30:00+01:00")
        app.buttons["Add task"].tap()
        let save = app.buttons["Save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertFalse(save.isEnabled)
        let title = app.textFields["Title"]
        title.tap()
        title.typeText("Renew passport")
        XCTAssertTrue(save.isEnabled)
        save.tap()
        XCTAssertFalse(save.waitForExistence(timeout: 2))
    }

    @MainActor
    func testTitleMessageAndHabitFields() {
        let app = UITestApp.launch(now: "2026-10-06T10:30:00+01:00")
        app.buttons["Add task"].tap()
        let title = app.textFields["Title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        title.typeText("A")
        title.typeText(XCUIKeyboardKey.delete.rawValue)
        XCTAssertTrue(app.staticTexts["Add a title"].waitForExistence(timeout: 2))
        app.buttons["Duration"].tap()
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Repeat on"].waitForExistence(timeout: 2))
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Daily target"].waitForExistence(timeout: 2))
    }

    /// SPEC T-38: notes typed in the editor show in Habit detail, and rows in Today and Tasks get the notes icon.
    @MainActor
    func testNotesShowInHabitDetailAndAsAnIconOnRows() {
        let app = UITestApp.launch(now: "2026-10-06T10:30:00+01:00")
        app.buttons["Add task"].tap()
        let title = app.textFields["Title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        app.buttons["Progress"].tap()
        title.tap()
        title.typeText("Gym")
        let notes = app.textFields["Notes"]
        notes.tap()
        notes.typeText("Leg day on Mondays")
        app.buttons["Save"].tap()

        let hasNotes = NSPredicate(format: "label CONTAINS 'Has notes'")
        let gym = app.staticTexts["Gym"]
        XCTAssertTrue(gym.waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any).matching(hasNotes).firstMatch.exists)
        gym.tap()
        let header = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS 'Leg day on Mondays'"))
        XCTAssertTrue(header.firstMatch.waitForExistence(timeout: 3))

        app.tabBars.buttons["Tasks"].tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(hasNotes).firstMatch.waitForExistence(timeout: 3))
    }

    @MainActor
    func testEndedPartsAreGreyedOut() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00")
        app.buttons["Add task"].tap()
        let morning = app.buttons["Morning"]
        XCTAssertTrue(morning.waitForExistence(timeout: 5))
        XCTAssertEqual(morning.value as? String, "Already over")
        XCTAssertFalse(morning.isEnabled)
        XCTAssertTrue(app.buttons["Afternoon"].isEnabled)
    }
}
