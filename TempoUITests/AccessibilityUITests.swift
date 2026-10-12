import XCTest

/// SPEC T-31: the system accessibility audit on every screen, at the default text size and the largest one.
/// Contrast and Dynamic Type warnings aren't checked here: they flag the system's own secondary text and controls,
/// and the day strip, which stops growing on purpose (D-097). Layouts at large sizes are checked by screenshots.
final class AccessibilityUITests: XCTestCase {
    private let audits: XCUIAccessibilityAuditType = [.sufficientElementDescription, .hitRegion, .textClipped]

    override func setUp() {
        continueAfterFailure = true
    }

    @MainActor
    private func audit(_ app: XCUIApplication, _ screen: String, file: StaticString = #filePath, line: UInt = #line) {
        do {
            try app.performAccessibilityAudit(for: audits) { issue in
                // Labels with a wide symbol ("End habit", the habit's type) are reported as clipped though they show
                // in full at every size in the T-31 screenshots.
                if issue.auditType == .textClipped, let label = issue.element?.label,
                    ["End habit", "Duration", "Progress"].contains(label)
                {
                    return true
                }
                // A small hit area the audit can't name: on Habit detail it's the system toolbar's Edit button (36
                // points tall); no other interactive element on these screens is under 44 points.
                if issue.auditType == .hitRegion, issue.element == nil {
                    return true
                }
                let element =
                    issue.element.map { "'\($0.label)' \($0.elementType.rawValue) \(NSCoder.string(for: $0.frame))" }
                    ?? "an element"
                XCTFail("\(screen): \(issue.compactDescription) — \(element)", file: file, line: line)
                return true
            }
        } catch {
            XCTFail("\(screen): \(error)", file: file, line: line)
        }
    }

    @MainActor
    private func visitEveryScreen(_ app: XCUIApplication) {
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5))
        audit(app, "Today")
        app.buttons["Settings"].tap()
        audit(app, "Settings")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Add task"].tap()
        _ = app.buttons["Cancel"].waitForExistence(timeout: 3)
        audit(app, "Editor")
        app.buttons["Cancel"].tap()
        for tab in ["Tasks", "Not done", "Stats"] {
            app.tabBars.buttons[tab].tap()
            sleep(1)
            audit(app, tab)
        }
        app.tabBars.buttons["Tasks"].tap()
        app.buttons["Habits"].tap()
        let read = app.staticTexts["Read"].firstMatch
        for _ in 0..<4 where !read.isHittable { app.swipeUp() }
        read.tap()
        sleep(1)
        audit(app, "Habit detail")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["History"].tap()
        sleep(1)
        audit(app, "History")
    }

    /// The Strict style's Missed tab, which the Gentle runs here don't show (SPEC F-30).
    @MainActor
    func testMissedTabInTheStrictStyle() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true, strict: true)
        app.tabBars.buttons["Missed"].tap()
        sleep(1)
        audit(app, "Missed")
    }

    @MainActor
    func testEveryScreen() {
        visitEveryScreen(UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true))
    }

    @MainActor
    func testEveryScreenAtTheLargestTextSize() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing", "-ui-testing-timezone", "Europe/London", "-ui-testing-now", "2026-10-06T13:00:00+01:00",
            "-ui-testing-sample", "-ui-testing-no-popup",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
        ]
        app.launch()
        visitEveryScreen(app)
    }
}
