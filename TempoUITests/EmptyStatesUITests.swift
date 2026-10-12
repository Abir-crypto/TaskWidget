import XCTest

/// SPEC T-29: the F-24 empty states in the app, and every "Add" button opening the editor with the right preset.
/// History, Missed and the Stats message are covered by `HistoryUITests`, `MissedUITests` and `StatsUITests`.
final class EmptyStatesUITests: XCTestCase {
    private let now = "2026-10-06T13:00:00+01:00"

    override func setUp() {
        continueAfterFailure = false
    }

    /// The editor is open with this type selected and, for one-time tasks, this day in its date picker.
    @MainActor
    private func assertEditor(
        _ app: XCUIApplication, type: String, day: String? = nil, file: StaticString = #filePath, line: UInt = #line
    ) {
        XCTAssertTrue(
            app.buttons["Cancel"].waitForExistence(timeout: 3), "The editor didn't open", file: file, line: line)
        XCTAssertTrue(app.buttons[type].firstMatch.isSelected, "\(type) isn't preset", file: file, line: line)
        if let day {
            let value = app.buttons["Date Picker"].firstMatch.value as? String ?? ""
            XCTAssertTrue(value.hasPrefix(day), "The date is \(value), not \(day)", file: file, line: line)
        }
        app.buttons["Cancel"].tap()
    }

    /// "Nothing planned for Thu 8 Oct"; the date's form follows the simulator's language.
    @MainActor
    private func message(_ app: XCUIApplication, _ start: String, day: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@ AND label CONTAINS %@", start, day))
            .firstMatch
    }

    @MainActor
    func testTodayEmptyStates() {
        let app = UITestApp.launch(now: now)
        XCTAssertTrue(app.staticTexts["No tasks today"].waitForExistence(timeout: 5))
        app.buttons["Add a task"].tap()
        assertEditor(app, type: "One-time", day: "6 Oct")

        app.buttons["day-20261008"].tap()
        XCTAssertTrue(message(app, "Nothing planned for", day: "8").waitForExistence(timeout: 3))
        app.buttons["Add a task"].tap()
        assertEditor(app, type: "One-time", day: "8 Oct")

        app.buttons["day-20261005"].tap()
        XCTAssertTrue(message(app, "Nothing was planned for", day: "5").waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Add a task"].exists)

        // With one task today, the parts without tasks say so in small grey text.
        app.buttons["day-20261006"].tap()
        app.buttons["Add task"].tap()
        let title = app.textFields["Title"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        title.tap()
        title.typeText("Renew passport")
        app.buttons["Anytime"].tap()
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Renew passport"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Nothing this afternoon"].exists)
        XCTAssertTrue(app.staticTexts["Nothing this evening"].exists)
        XCTAssertTrue(app.staticTexts["Nothing tonight"].exists)
    }

    @MainActor
    func testTasksAndStatsAddButtons() {
        let app = UITestApp.launch(now: now)
        app.tabBars.buttons["Tasks"].tap()
        app.buttons["Habits"].tap()
        XCTAssertTrue(app.staticTexts["No habits yet"].waitForExistence(timeout: 3))
        app.buttons["Add a habit"].tap()
        assertEditor(app, type: "Progress")

        app.buttons["One-time"].tap()
        XCTAssertTrue(app.staticTexts["No upcoming tasks"].waitForExistence(timeout: 3))
        app.buttons["Add a task"].tap()
        assertEditor(app, type: "One-time", day: "6 Oct")

        app.tabBars.buttons["Stats"].tap()
        XCTAssertTrue(app.staticTexts["Add a habit to see your stats"].waitForExistence(timeout: 3))
        app.buttons["Add a habit"].firstMatch.tap()
        assertEditor(app, type: "Progress")
    }

    @MainActor
    func testHabitDetailWithNoData() {
        let app = UITestApp.launch(now: now)
        app.tabBars.buttons["Tasks"].tap()
        app.buttons["Habits"].tap()
        app.buttons["Add a habit"].tap()
        let title = app.textFields["Title"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        title.tap()
        title.typeText("Stretch")
        app.buttons["Save"].tap()
        app.staticTexts["Stretch"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["No data yet. Check back after its first day."].waitForExistence(timeout: 3))
    }

    @MainActor
    func testTaskPickerAddsADurationTask() {
        let app = UITestApp.launch(now: "2026-10-06T18:00:00+01:00", finishedTimer: 600)
        XCTAssertTrue(app.staticTexts["No duration tasks yet"].waitForExistence(timeout: 5))
        app.buttons["Add a duration task"].tap()
        assertEditor(app, type: "Duration")
        // The picker comes back after the editor (D-084), still empty.
        XCTAssertTrue(app.staticTexts["No duration tasks yet"].waitForExistence(timeout: 3))
        app.buttons["Discard"].firstMatch.tap()
    }

    /// The Day and Now widgets' "No tasks today" open this link.
    @MainActor
    func testEmptyWidgetLinkOpensTheEditorForToday() throws {
        let app = UITestApp.launch(now: now)
        XCTAssertTrue(app.staticTexts["No tasks today"].waitForExistence(timeout: 5))
        app.open(try XCTUnwrap(URL(string: "tempo://new?day=20261006")))
        assertEditor(app, type: "One-time", day: "6 Oct")
    }
}
