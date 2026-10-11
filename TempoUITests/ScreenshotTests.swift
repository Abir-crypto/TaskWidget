import XCTest

/// Saves screenshots of screens for visual review. Skipped unless `TEMPO_SCREENSHOTS` names a folder; pass it
/// to `xcodebuild` as `TEST_RUNNER_TEMPO_SCREENSHOTS=<folder>`.
final class ScreenshotTests: XCTestCase {
    private var folder: URL?

    override func setUpWithError() throws {
        let path = ProcessInfo.processInfo.environment["TEMPO_SCREENSHOTS"]
        try XCTSkipIf(path == nil, "Set TEMPO_SCREENSHOTS to save screenshots")
        folder = path.map { URL(filePath: $0) }
        continueAfterFailure = true
    }

    @MainActor
    private func save(_ app: XCUIApplication, _ name: String) {
        guard let folder else { return }
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? app.screenshot().pngRepresentation.write(to: folder.appending(path: "\(name).png"))
    }

    /// The whole screen, which comes out the right way round in landscape on iPad, unlike an app's screenshot.
    @MainActor
    private func saveScreen(_ name: String) {
        guard let folder else { return }
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: folder.appending(path: "\(name).png"))
    }

    @MainActor
    func testSettings() {
        let app = UITestApp.launch(now: "2026-10-06T10:30:00+01:00")
        app.buttons["Settings"].tap()
        _ = app.navigationBars["Settings"].waitForExistence(timeout: 5)
        save(app, "settings-1")
        app.swipeUp()
        save(app, "settings-2")
    }

    @MainActor
    func testGuide() {
        let app = UITestApp.launch(guide: true)
        _ = app.staticTexts["Welcome to Tempo"].waitForExistence(timeout: 5)
        for page in 1...6 {
            save(app, "guide-\(page)")
            app.buttons["Next"].tap()
            sleep(1)
        }
        save(app, "guide-7")
    }

    /// Every screen in portrait and landscape, for checking the readable width on iPad (SPEC F-25).
    @MainActor
    func testEveryScreenInBothOrientations() {
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            let suffix = orientation == .portrait ? "portrait" : "landscape"
            let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
            _ = app.navigationBars["Today"].waitForExistence(timeout: 5)
            sleep(2)
            saveScreen("today-\(suffix)")
            app.buttons["Settings"].tap()
            sleep(1)
            saveScreen("settings-\(suffix)")
            app.navigationBars.buttons.element(boundBy: 0).tap()
            app.buttons["Add task"].tap()
            sleep(1)
            saveScreen("editor-\(suffix)")
            app.buttons["Cancel"].tap()
            for tab in ["Tasks", "Missed", "Stats"] {
                app.buttons[tab].firstMatch.tap()
                sleep(1)
                saveScreen("\(tab.lowercased())-\(suffix)")
            }
            app.buttons["Tasks"].firstMatch.tap()
            app.buttons["Habits"].tap()
            let read = app.staticTexts["Read"].firstMatch
            for _ in 0..<4 where !read.isHittable { app.swipeUp() }
            read.tap()
            sleep(1)
            saveScreen("habit-\(suffix)")
            app.navigationBars.buttons.element(boundBy: 0).tap()
            app.buttons["History"].firstMatch.tap()
            sleep(1)
            saveScreen("history-\(suffix)")
            app.terminate()
        }
        XCUIDevice.shared.orientation = .portrait
    }

    /// Drags the window's corner handle to make Tempo a narrow window, photographs it, then restores the size
    /// (SPEC F-25: a narrow window looks like the phone). iPad only.
    @MainActor
    func testNarrowWindow() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        _ = app.navigationBars["Today"].waitForExistence(timeout: 5)
        sleep(1)
        saveScreen("narrow-0-full")
        let screen = app.coordinate(withNormalizedOffset: .zero)
        let frame = app.windows.firstMatch.frame
        let corner = screen.withOffset(CGVector(dx: frame.maxX - 6, dy: frame.maxY - 6))
        corner.press(forDuration: 0.5, thenDragTo: screen.withOffset(CGVector(dx: 420, dy: frame.maxY - 60)))
        sleep(2)
        saveScreen("narrow-1-today")
        app.buttons["Tasks"].firstMatch.tap()
        sleep(1)
        saveScreen("narrow-2-tasks")
        app.buttons["Stats"].firstMatch.tap()
        sleep(1)
        saveScreen("narrow-3-stats")
        let narrow = app.windows.firstMatch.frame
        let back = screen.withOffset(CGVector(dx: narrow.maxX - 6, dy: narrow.maxY - 6))
        back.press(forDuration: 0.5, thenDragTo: screen.withOffset(CGVector(dx: frame.maxX, dy: frame.maxY)))
        sleep(2)
        saveScreen("narrow-4-restored")
        XCUIDevice.shared.orientation = .portrait
    }

    /// Chooses the theme in `TEMPO_THEME` (default "Pink") in Settings and photographs the screens it colors
    /// (SPEC F-27).
    @MainActor
    func testThemeOnEveryScreen() {
        let theme = ProcessInfo.processInfo.environment["TEMPO_THEME"] ?? "Pink"
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        _ = app.navigationBars["Today"].waitForExistence(timeout: 5)
        app.buttons["Settings"].tap()
        let swatch = app.buttons[theme]
        for _ in 0..<4 where !swatch.isHittable { app.swipeUp() }
        swatch.tap()
        sleep(1)
        saveScreen("theme-1-settings")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(1)
        saveScreen("theme-2-today")
        app.buttons["Add task"].tap()
        sleep(1)
        saveScreen("theme-3-editor")
        app.buttons["Cancel"].tap()
        // A habit's "Delete with history" dialog has a plain option (End habit), which shows the alert tint.
        app.staticTexts["Gym"].firstMatch.tap()
        app.buttons["Edit"].firstMatch.tap()
        let delete = app.buttons["Delete with history"]
        for _ in 0..<4 where !delete.isHittable { app.swipeUp() }
        delete.tap()
        sleep(1)
        saveScreen("theme-4-dialog")
        // A tap away closes the dialog; then leave the editor and Habit detail.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12)).tap()
        sleep(1)
        if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
        sleep(1)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(1)
        for tab in ["Tasks", "Missed", "Stats"] {
            app.tabBars.buttons[tab].tap()
            sleep(1)
            saveScreen("theme-5-\(tab.lowercased())")
        }
        app.tabBars.buttons["Tasks"].tap()
        app.buttons["Habits"].tap()
        app.staticTexts["Read"].firstMatch.tap()
        sleep(1)
        saveScreen("theme-6-habit")
    }

    @MainActor
    func testEditor() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00")
        app.buttons["Add task"].tap()
        _ = app.buttons["Save"].waitForExistence(timeout: 5)
        save(app, "editor-1-new")
        app.buttons["Duration"].tap()
        app.buttons["Fixed time"].tap()
        save(app, "editor-2-duration")
        app.swipeUp()
        save(app, "editor-3-duration-scrolled")
    }

    @MainActor
    func testToday() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        _ = app.navigationBars["Today"].waitForExistence(timeout: 5)
        save(app, "today-1")
        app.swipeUp()
        save(app, "today-2-scrolled")
        app.swipeDown()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Morning'")).firstMatch.tap()
        save(app, "today-3-morning-expanded")
        app.buttons["day-20261008"].tap()
        save(app, "today-4-thursday")
        app.buttons["day-20261005"].tap()
        save(app, "today-5-monday")
    }

    @MainActor
    func testTodayEmpty() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00")
        _ = app.navigationBars["Today"].waitForExistence(timeout: 5)
        save(app, "today-empty")
    }

    @MainActor
    func testTasks() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        app.tabBars.buttons["Tasks"].tap()
        app.buttons["Habits"].tap()
        _ = app.staticTexts["Take medicine"].waitForExistence(timeout: 5)
        save(app, "tasks-habits")
        app.buttons["One-time"].tap()
        save(app, "tasks-onetime")
    }

    @MainActor
    func testHistory() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        app.tabBars.buttons["Tasks"].tap()
        app.buttons["History"].tap()
        app.buttons["Habits"].tap()
        _ = app.staticTexts["Meditate"].waitForExistence(timeout: 5)
        save(app, "history-habits")
    }

    @MainActor
    func testHabitDetail() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Read'")).firstMatch.tap()
        _ = app.staticTexts["This week"].waitForExistence(timeout: 5)
        save(app, "habit-1")
        app.swipeUp()
        save(app, "habit-2")
        app.swipeUp()
        save(app, "habit-3")
    }

    @MainActor
    func testMissed() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        app.tabBars.buttons["Missed"].tap()
        _ = app.staticTexts["Stretch"].waitForExistence(timeout: 5)
        save(app, "missed-1")
        app.buttons["Sort and filter"].tap()
        _ = app.navigationBars["Sort & filter"].waitForExistence(timeout: 3)
        save(app, "missed-2-filter")
    }

    @MainActor
    func testMissedPopup() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true, missedPopup: true)
        _ = app.buttons["Not now"].waitForExistence(timeout: 5)
        save(app, "missed-popup")
    }

    @MainActor
    func testStats() {
        let app = UITestApp.launch(now: "2026-10-06T13:00:00+01:00", sample: true)
        app.tabBars.buttons["Stats"].tap()
        _ = app.staticTexts["Overview"].waitForExistence(timeout: 5)
        save(app, "stats-1-week")
        app.swipeUp()
        save(app, "stats-2-week-scrolled")
        app.swipeUp()
        save(app, "stats-3-week-scrolled")
        app.swipeDown()
        app.swipeDown()
        app.buttons["Month"].tap()
        save(app, "stats-4-month")
        app.buttons["Year"].tap()
        save(app, "stats-5-year")
    }

    @MainActor
    func testTimer() {
        let app = UITestApp.launch(now: "2026-10-06T18:00:00+01:00", sample: true)
        app.buttons["Start timer"].tap()
        _ = app.buttons["Pause"].waitForExistence(timeout: 3)
        save(app, "timer-1-bar")
        app.staticTexts["Read"].firstMatch.tap()
        _ = app.staticTexts["10 of 30 min today"].waitForExistence(timeout: 3)
        save(app, "timer-2-screen")
    }

    @MainActor
    func testTaskPicker() {
        let app = UITestApp.launch(now: "2026-10-06T18:00:00+01:00", sample: true, finishedTimer: 1_080)
        _ = app.staticTexts["Add 18 min to"].waitForExistence(timeout: 5)
        save(app, "picker-1")
        app.staticTexts["Read"].firstMatch.tap()
        _ = app.buttons["Undo"].waitForExistence(timeout: 3)
        save(app, "picker-2-toast")
    }

    /// Adds the Timer widget to the Home Screen through SpringBoard and photographs each step.
    @MainActor
    func testWidgetOnHomeScreen() {
        let app = UITestApp.launch()
        _ = app.wait(for: .runningForeground, timeout: 5)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCUIDevice.shared.press(.home)
        sleep(1)
        save(springboard, "widget-1-home")
        springboard.press(forDuration: 2)
        sleep(1)
        save(springboard, "widget-2-jiggle")
        let edit = springboard.buttons["Edit"]
        if edit.waitForExistence(timeout: 3) { edit.tap() }
        sleep(1)
        save(springboard, "widget-3-edit")
        let add = springboard.buttons["Add Widget"]
        if add.waitForExistence(timeout: 3) { add.tap() }
        sleep(2)
        save(springboard, "widget-4-gallery")
        let search = springboard.searchFields.firstMatch
        if search.waitForExistence(timeout: 3) {
            search.tap()
            search.typeText("Tempo")
        }
        sleep(1)
        springboard.staticTexts["Tempo"].firstMatch.tap()
        sleep(2)
        save(springboard, "widget-5-tempo")
        let candidates = springboard.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Widget'"))
            .allElementsBoundByIndex
        if let button = candidates.last(where: { $0.isHittable }) {
            button.tap()
        } else {
            springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.905)).tap()
        }
        sleep(2)
        save(springboard, "widget-6-added")
        let done = springboard.buttons["Done"].firstMatch
        if done.waitForExistence(timeout: 2) { done.tap() }
        sleep(2)
        save(springboard, "widget-7-home")
        print("SPRINGBOARD TREE:", springboard.debugDescription.prefix(8000))
    }

    /// Uses the Timer widget's buttons on the Home Screen (run `testWidgetOnHomeScreen` first).
    @MainActor
    func testTimerWidgetButtons() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCUIDevice.shared.press(.home)
        sleep(1)
        // The widget sits on the page with the Tempo app.
        for _ in 0..<3 where !springboard.buttons["Start"].firstMatch.exists { springboard.swipeLeft() }
        let start = springboard.buttons["Start"].firstMatch
        if start.waitForExistence(timeout: 5) { start.tap() }
        sleep(4)
        save(springboard, "widget-8-running")
        let pause = springboard.buttons["Pause"].firstMatch
        if pause.waitForExistence(timeout: 5) { pause.tap() }
        sleep(4)
        save(springboard, "widget-9-paused")
        let done = springboard.buttons["Done"].firstMatch
        if done.waitForExistence(timeout: 5) { done.tap() }
        sleep(5)
        save(XCUIApplication(), "widget-10-app-after-done")
        XCUIDevice.shared.press(.home)
        sleep(1)
        for _ in 0..<3 where !springboard.buttons["Start"].firstMatch.exists { springboard.swipeLeft() }
        sleep(1)
        save(springboard, "widget-11-idle-again")
    }

    /// Starts a habit timer in the real app and photographs the Timer widget showing it without controls, then
    /// deletes the habit again (run `testWidgetOnHomeScreen` first).
    @MainActor
    func testTimerWidgetShowsAHabitTimer() {
        let app = XCUIApplication()
        app.launch()
        finishGuideIfShown(app)
        if app.buttons["Not now"].waitForExistence(timeout: 2) { app.buttons["Not now"].tap() }
        app.buttons["Today"].firstMatch.tap()
        app.buttons["Add task"].firstMatch.tap()
        _ = app.buttons["Duration"].waitForExistence(timeout: 5)
        app.buttons["Duration"].tap()
        let title = app.textFields["Title"]
        title.tap()
        title.typeText("Widget check")
        app.buttons["Anytime"].tap()
        app.buttons["Save"].tap()
        let play = app.buttons["Start timer"].firstMatch
        _ = play.waitForExistence(timeout: 5)
        play.tap()
        sleep(1)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCUIDevice.shared.press(.home)
        sleep(1)
        XCUIDevice.shared.press(.home)
        sleep(1)
        // The Timer widget's page; give the widgets a moment to reload.
        for _ in 0..<3
        where !springboard.buttons["Start"].firstMatch.isHittable
            && !springboard.staticTexts["Widget check"].firstMatch.exists
        {
            springboard.swipeLeft()
            sleep(1)
        }
        sleep(5)
        save(springboard, "widget-12-habit-timer")

        app.activate()
        Self.deleteHabit(named: "Widget check", in: app)
    }

    /// Deletes a habit with its history through Tasks › Habits, which also discards its timer.
    @MainActor
    static func deleteHabit(named name: String, in app: XCUIApplication) {
        app.tabBars.buttons["Tasks"].tap()
        app.buttons["Habits"].tap()
        let row = app.cells.containing(.staticText, identifier: name).firstMatch
        guard row.waitForExistence(timeout: 3) else { return }
        row.tap()
        app.navigationBars.buttons["Edit"].tap()
        let delete = app.buttons["Delete with history"].firstMatch
        for _ in 0..<4 where !delete.isHittable { app.swipeUp() }
        delete.tap()
        let confirm = app.buttons.matching(NSPredicate(format: "label == 'Delete with history'"))
            .allElementsBoundByIndex
            .last { $0.isHittable }
        confirm?.tap()
        sleep(1)
    }

    /// Removes the habit `testTimerWidgetShowsAHabitTimer` adds, if a run stopped halfway.
    @MainActor
    func testCleanUpWidgetCheckHabit() {
        let app = XCUIApplication()
        app.launch()
        finishGuideIfShown(app)
        if app.buttons["Not now"].waitForExistence(timeout: 2) { app.buttons["Not now"].tap() }
        Self.deleteHabit(named: "Widget check", in: app)
        app.tabBars.buttons["Tasks"].tap()
        save(app, "cleanup-tasks")
    }

    /// Adds the Now widget (large) to the Home Screen with a task in the real store, photographs list mode,
    /// checks the task from the widget, then cleans up.
    @MainActor
    func testNowWidgetOnHomeScreen() {
        let app = XCUIApplication()
        app.launch()
        finishGuideIfShown(app)
        if app.buttons["Not now"].waitForExistence(timeout: 2) { app.buttons["Not now"].tap() }
        app.tabBars.buttons["Today"].tap()
        app.buttons["Add task"].tap()
        let title = app.textFields["Title"]
        title.tap()
        title.typeText("Widget check")
        app.buttons["Anytime"].tap()
        app.buttons["Save"].tap()
        sleep(1)

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCUIDevice.shared.press(.home)
        sleep(1)
        for _ in 0..<3 where !springboard.icons["Contacts"].exists || !springboard.icons["Contacts"].isHittable {
            springboard.swipeLeft()
        }
        let alreadyAdded = springboard.buttons.matching(NSPredicate(format: "value == 'Widget check'")).firstMatch
            .waitForExistence(timeout: 3)
        if !alreadyAdded { addNowWidget(springboard) }
        sleep(3)
        save(springboard, "now-2-home")
        let checkbox = springboard.buttons.matching(NSPredicate(format: "value == 'Widget check'")).firstMatch
        if checkbox.waitForExistence(timeout: 3) { checkbox.tap() }
        sleep(10)
        save(springboard, "now-3-checked")
        app.activate()
        app.tabBars.buttons["Today"].tap()
        sleep(1)
        save(app, "now-4-app-today")
        let row = app.staticTexts["Widget check"].firstMatch
        if row.waitForExistence(timeout: 3) {
            row.swipeLeft()
            if app.buttons["Delete"].waitForExistence(timeout: 2) { app.buttons["Delete"].tap() }
            if app.buttons["Delete task"].waitForExistence(timeout: 2) { app.buttons["Delete task"].tap() }
        }
        sleep(1)
    }

    @MainActor
    private func addNowWidget(_ springboard: XCUIApplication) {
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6)).press(forDuration: 2)
        sleep(1)
        if springboard.buttons["Edit"].waitForExistence(timeout: 3) { springboard.buttons["Edit"].tap() }
        sleep(1)
        let add = springboard.buttons["Add Widget"].firstMatch
        if add.waitForExistence(timeout: 3) { add.tap() }
        sleep(2)
        let search = springboard.searchFields.firstMatch
        if search.waitForExistence(timeout: 3) {
            search.tap()
            search.typeText("Tempo")
        }
        sleep(1)
        springboard.staticTexts["Tempo"].firstMatch.tap()
        sleep(2)
        springboard.swipeLeft()
        sleep(2)
        save(springboard, "now-1-gallery")
        let candidates = springboard.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Widget'"))
            .allElementsBoundByIndex
        if let button = candidates.last(where: { $0.isHittable }) {
            button.tap()
        } else {
            springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.905)).tap()
        }
        sleep(2)
        if springboard.buttons["Done"].firstMatch.waitForExistence(timeout: 2) {
            springboard.buttons["Done"].firstMatch.tap()
        }
    }

    /// Taps the first checkbox in the Now widget (already on the Home Screen, top of the Timer widget's page) and
    /// checks the task is done in the app, then cleans up.
    @MainActor
    func testNowWidgetCheckbox() {
        let app = XCUIApplication()
        app.launch()
        finishGuideIfShown(app)
        if app.buttons["Not now"].waitForExistence(timeout: 2) { app.buttons["Not now"].tap() }
        app.tabBars.buttons["Today"].tap()
        app.buttons["Add task"].tap()
        let title = app.textFields["Title"]
        title.tap()
        title.typeText("Widget check")
        app.buttons["Anytime"].tap()
        app.buttons["Save"].tap()
        sleep(1)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCUIDevice.shared.press(.home)
        sleep(1)
        XCUIDevice.shared.press(.home)
        sleep(1)
        // The Now widget is at the top of the Timer widget's page.
        for _ in 0..<3 where !springboard.buttons["Start"].firstMatch.isHittable { springboard.swipeLeft() }
        sleep(3)
        save(springboard, "check-1-before")
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.14, dy: 0.167)).tap()
        sleep(8)
        save(springboard, "check-2-after")
        app.activate()
        app.tabBars.buttons["Today"].tap()
        sleep(1)
        save(app, "check-3-app")
        let row = app.staticTexts["Widget check"].firstMatch
        if row.waitForExistence(timeout: 3) {
            row.swipeLeft()
            if app.buttons["Delete"].waitForExistence(timeout: 2) { app.buttons["Delete"].tap() }
            if app.buttons["Delete task"].waitForExistence(timeout: 2) { app.buttons["Delete task"].tap() }
        }
        sleep(1)
    }

    /// Adds the Day widget (medium) next to two real tasks, photographs it, then deletes the tasks.
    @MainActor
    func testDayWidgetOnHomeScreen() {
        let app = XCUIApplication()
        app.launch()
        finishGuideIfShown(app)
        if app.buttons["Not now"].waitForExistence(timeout: 2) { app.buttons["Not now"].tap() }
        for name in ["Day check A", "Day check B"] {
            app.tabBars.buttons["Today"].tap()
            app.buttons["Add task"].tap()
            let title = app.textFields["Title"]
            title.tap()
            title.typeText(name)
            app.buttons["Anytime"].tap()
            app.buttons["Save"].tap()
            sleep(1)
        }
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCUIDevice.shared.press(.home)
        sleep(1)
        for _ in 0..<3 where !springboard.icons["Contacts"].exists || !springboard.icons["Contacts"].isHittable {
            springboard.swipeLeft()
        }
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.62, dy: 0.76)).press(forDuration: 2)
        sleep(1)
        if springboard.buttons["Edit"].waitForExistence(timeout: 3) { springboard.buttons["Edit"].tap() }
        sleep(1)
        if springboard.buttons["Add Widget"].firstMatch.waitForExistence(timeout: 3) {
            springboard.buttons["Add Widget"].firstMatch.tap()
        }
        sleep(2)
        let search = springboard.searchFields.firstMatch
        if search.waitForExistence(timeout: 3) {
            search.tap()
            search.typeText("Tempo")
        }
        sleep(1)
        springboard.staticTexts["Tempo"].firstMatch.tap()
        sleep(2)
        springboard.swipeLeft()
        sleep(2)
        save(springboard, "day-1-gallery")
        let candidates = springboard.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Widget'"))
            .allElementsBoundByIndex
        if let button = candidates.last(where: { $0.isHittable }) {
            button.tap()
        } else {
            springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.905)).tap()
        }
        sleep(2)
        if springboard.buttons["Done"].firstMatch.waitForExistence(timeout: 2) {
            springboard.buttons["Done"].firstMatch.tap()
        }
        sleep(3)
        save(springboard, "day-2-home")

        app.activate()
        app.tabBars.buttons["Today"].tap()
        for name in ["Day check A", "Day check B"] {
            let row = app.staticTexts[name].firstMatch
            guard row.waitForExistence(timeout: 3) else { continue }
            row.swipeLeft()
            if app.buttons["Delete"].waitForExistence(timeout: 2) { app.buttons["Delete"].tap() }
            if app.buttons["Delete task"].waitForExistence(timeout: 2) { app.buttons["Delete task"].tap() }
            sleep(1)
        }
    }

    /// Taps the empty Now widget (top of the second Home Screen page) and photographs what opens: the editor for
    /// today, after the first-launch guide if the app hasn't finished it on this simulator.
    @MainActor
    func testEmptyNowWidgetOpensTheEditor() {
        let app = XCUIApplication()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCUIDevice.shared.press(.home)
        sleep(1)
        XCUIDevice.shared.press(.home)
        sleep(1)
        springboard.swipeLeft()
        sleep(2)
        save(springboard, "empty-1-home")
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)).tap()
        sleep(3)
        save(app, "empty-2-opened")
        finishGuideIfShown(app)
        sleep(1)
        save(app, "empty-3-after-guide")
        if app.buttons["Cancel"].waitForExistence(timeout: 2) { app.buttons["Cancel"].tap() }
    }

    /// Adds Tempo widgets to an iPad's Home Screen next to a real task and photographs them, then deletes the
    /// task (SPEC F-25). `TEMPO_WIDGET_SWIPES` lists how far into Tempo's gallery each widget is, e.g. "0,1,2".
    @MainActor
    func testWidgetsOnIPadHomeScreen() {
        let app = XCUIApplication()
        app.launch()
        finishGuideIfShown(app)
        if app.buttons["Not now"].waitForExistence(timeout: 2) { app.buttons["Not now"].tap() }
        app.buttons["Add task"].firstMatch.tap()
        let title = app.textFields["Title"]
        title.tap()
        title.typeText("iPad check")
        app.buttons["Anytime"].tap()
        app.buttons["Save"].tap()
        sleep(1)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let swipes = (ProcessInfo.processInfo.environment["TEMPO_WIDGET_SWIPES"] ?? "0")
            .split(separator: ",").compactMap { Int($0) }
        for (index, count) in swipes.enumerated() {
            XCUIDevice.shared.press(.home)
            sleep(2)
            springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75)).press(forDuration: 2)
            sleep(1)
            if springboard.buttons["Edit"].waitForExistence(timeout: 3) { springboard.buttons["Edit"].tap() }
            sleep(1)
            if springboard.buttons["Add Widget"].firstMatch.waitForExistence(timeout: 3) {
                springboard.buttons["Add Widget"].firstMatch.tap()
            }
            sleep(2)
            let search = springboard.searchFields.firstMatch
            guard search.waitForExistence(timeout: 3) else {
                saveScreen("ipad-x-no-gallery-\(index)")
                return
            }
            search.tap()
            search.typeText("Tempo")
            sleep(1)
            springboard.staticTexts["Tempo"].firstMatch.tap()
            sleep(2)
            for _ in 0..<count {
                springboard.swipeLeft()
                sleep(1)
            }
            saveScreen("ipad-\(index)-gallery")
            let add = springboard.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Widget'"))
                .allElementsBoundByIndex.last { $0.isHittable }
            add?.tap()
            sleep(2)
            if springboard.buttons["Done"].firstMatch.waitForExistence(timeout: 2) {
                springboard.buttons["Done"].firstMatch.tap()
            }
            sleep(3)
            saveScreen("ipad-\(index)-home")
        }
        app.activate()
        app.buttons["Today"].firstMatch.tap()
        let row = app.staticTexts["iPad check"].firstMatch
        if row.waitForExistence(timeout: 3) {
            row.swipeLeft()
            if app.buttons["Delete"].waitForExistence(timeout: 2) { app.buttons["Delete"].tap() }
            if app.buttons["Delete task"].waitForExistence(timeout: 2) { app.buttons["Delete task"].tap() }
        }
    }

    /// Photographs Home Screen pages 1–4 in each style named in `TEMPO_STYLES` (default "Tinted,Clear") next to a
    /// real task, then puts the Default style back and deletes the task (SPEC F-17: widgets adapt to tinted
    /// styles).
    @MainActor
    func testWidgetStyles() {
        let app = XCUIApplication()
        app.launch()
        finishGuideIfShown(app)
        if app.buttons["Not now"].waitForExistence(timeout: 2) { app.buttons["Not now"].tap() }
        app.buttons["Add task"].firstMatch.tap()
        let title = app.textFields["Title"]
        title.tap()
        title.typeText("Style check")
        app.buttons["Anytime"].tap()
        app.buttons["Save"].tap()
        sleep(1)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let styles = (ProcessInfo.processInfo.environment["TEMPO_STYLES"] ?? "Tinted,Clear")
            .split(separator: ",").map(String.init)
        for style in styles {
            applyHomeScreenStyle(style, springboard)
            XCUIDevice.shared.press(.home)
            sleep(1)
            XCUIDevice.shared.press(.home)
            sleep(2)
            for page in 1...4 {
                saveScreen("style-\(style.lowercased())-\(page)")
                springboard.swipeLeft()
                sleep(1)
            }
        }
        if styles.last != "Default" { applyHomeScreenStyle("Default", springboard) }
        app.activate()
        app.buttons["Today"].firstMatch.tap()
        let row = app.staticTexts["Style check"].firstMatch
        if row.waitForExistence(timeout: 3) {
            row.swipeLeft()
            if app.buttons["Delete"].waitForExistence(timeout: 2) { app.buttons["Delete"].tap() }
            if app.buttons["Delete task"].waitForExistence(timeout: 2) { app.buttons["Delete task"].tap() }
        }
    }

    /// Home Screen › Edit › Customize › Default, Dark, Clear or Tinted.
    @MainActor
    private func applyHomeScreenStyle(_ style: String, _ springboard: XCUIApplication) {
        XCUIDevice.shared.press(.home)
        sleep(1)
        XCUIDevice.shared.press(.home)
        sleep(1)
        springboard.swipeLeft()
        sleep(1)
        // The empty end of the dock opens the edit menu without touching a widget.
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.82, dy: 0.935)).press(forDuration: 2)
        if springboard.buttons["Edit"].waitForExistence(timeout: 3) { springboard.buttons["Edit"].tap() }
        if springboard.buttons["Customize"].waitForExistence(timeout: 3) { springboard.buttons["Customize"].tap() }
        if springboard.buttons[style].waitForExistence(timeout: 3) { springboard.buttons[style].tap() }
        sleep(1)
        let dismiss = springboard.otherElements["PopoverDismissRegion"].firstMatch
        if dismiss.exists {
            dismiss.tap()
        } else {
            // The status bar is a safe place to tap away the panel.
            springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.02)).tap()
        }
        sleep(1)
        XCUIDevice.shared.press(.home)
        sleep(1)
    }

    /// Deletes tasks that interrupted widget tests left in the simulator's real store, by the titles in
    /// `TEMPO_DELETE` (comma-separated), from Today.
    @MainActor
    func testDeleteLeftoverTasks() {
        let app = XCUIApplication()
        app.launch()
        finishGuideIfShown(app)
        if app.buttons["Not now"].waitForExistence(timeout: 2) { app.buttons["Not now"].tap() }
        app.buttons["Today"].firstMatch.tap()
        let titles = (ProcessInfo.processInfo.environment["TEMPO_DELETE"] ?? "").split(separator: ",").map(String.init)
        for title in titles {
            for _ in 0..<10 {
                let row = app.staticTexts[title].firstMatch
                guard row.waitForExistence(timeout: 2) else { break }
                for _ in 0..<4 where !row.isHittable { app.swipeUp() }
                row.swipeLeft()
                if app.buttons["Delete"].waitForExistence(timeout: 2) { app.buttons["Delete"].tap() }
                if app.buttons["Delete task"].waitForExistence(timeout: 2) { app.buttons["Delete task"].tap() }
                sleep(1)
            }
        }
        save(app, "leftovers-after")
    }

    /// Allows notifications, adds a task at a fixed time about 20 minutes ahead, and waits on the Home Screen for its
    /// fixed-time reminder (10 minutes before by default); photographs the banner, taps it, photographs where it
    /// leads, then deletes the task (manual QA, ios.md §13). Takes about 15 minutes.
    @MainActor
    func testFixedTimeReminderArrives() {
        let app = XCUIApplication()
        app.launch()
        finishGuideIfShown(app)
        if app.buttons["Not now"].waitForExistence(timeout: 2) { app.buttons["Not now"].tap() }
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        // Permission, from Settings.
        app.buttons["Settings"].firstMatch.tap()
        let allow = app.buttons["Allow notifications"]
        for _ in 0..<3 where !allow.exists { app.swipeUp() }
        if allow.exists {
            allow.tap()
            let systemAllow = springboard.alerts.buttons["Allow"]
            if systemAllow.waitForExistence(timeout: 5) { systemAllow.tap() }
            sleep(1)
        }
        save(app, "reminder-0-settings")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // A task at the 5-minute step 15–20 minutes ahead, set on the hour, minute and AM/PM wheels.
        let target = Calendar.current.dateComponents([.hour, .minute], from: Date().addingTimeInterval(15 * 60))
        var hour = target.hour ?? 0
        var minute = ((target.minute ?? 0) + 4) / 5 * 5
        if minute == 60 {
            minute = 0
            hour = (hour + 1) % 24
        }
        app.buttons["Add task"].firstMatch.tap()
        let title = app.textFields["Title"]
        title.tap()
        title.typeText("Reminder check")
        app.buttons["Fixed time"].tap()
        app.datePickers["Time"].buttons.firstMatch.tap()
        let wheels = app.pickerWheels
        _ = wheels.firstMatch.waitForExistence(timeout: 3)
        wheels.element(boundBy: 0).adjust(toPickerWheelValue: String((hour + 11) % 12 + 1))
        wheels.element(boundBy: 1).adjust(toPickerWheelValue: String(format: "%02d", minute))
        wheels.element(boundBy: 2).adjust(toPickerWheelValue: hour < 12 ? "AM" : "PM")
        // Close the wheels with a tap on the title bar; the open wheels cover the Title field.
        app.navigationBars.staticTexts["New task"].tap()
        sleep(1)
        save(app, "reminder-1-editor")
        app.buttons["Save"].tap()
        sleep(1)

        XCUIDevice.shared.press(.home)
        let banner = springboard.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS 'Reminder check'")).firstMatch
        let arrived = banner.waitForExistence(timeout: 20 * 60)
        saveScreen("reminder-2-banner")
        if arrived {
            print("REMINDER banner: \(banner.label)")
            banner.tap()
            sleep(3)
            save(app, "reminder-3-opened")
        }
        app.activate()
        app.buttons["Today"].firstMatch.tap()
        let row = app.staticTexts["Reminder check"].firstMatch
        if row.waitForExistence(timeout: 3) {
            row.swipeLeft()
            if app.buttons["Delete"].waitForExistence(timeout: 2) { app.buttons["Delete"].tap() }
            if app.buttons["Delete task"].waitForExistence(timeout: 2) { app.buttons["Delete task"].tap() }
        }
        XCTAssertTrue(arrived, "The fixed-time reminder didn't arrive")
    }

    /// Adds a fixed-time task in the real app, relaunches it in New York's time zone and checks the task keeps its
    /// wall-clock time, then deletes it (manual QA, ios.md §13: time zone changes keep wall-clock times).
    @MainActor
    func testFixedTimeKeepsItsWallClockTimeInAnotherZone() {
        var app = XCUIApplication()
        app.launch()
        finishGuideIfShown(app)
        if app.buttons["Not now"].waitForExistence(timeout: 2) { app.buttons["Not now"].tap() }
        app.buttons["Today"].firstMatch.tap()
        app.buttons["Add task"].firstMatch.tap()
        let title = app.textFields["Title"]
        title.tap()
        title.typeText("Zone check")
        app.buttons["Fixed time"].tap()
        let time = app.datePickers["Time"].buttons.firstMatch.value as? String ?? ""
        app.buttons["Save"].tap()
        sleep(1)
        save(app, "zone-1-home-zone")
        XCTAssertTrue(app.staticTexts[time].exists, "\(time) isn't shown")
        app.terminate()

        app = XCUIApplication()
        app.launchEnvironment["TZ"] = "America/New_York"
        app.launch()
        if app.buttons["Not now"].waitForExistence(timeout: 2) { app.buttons["Not now"].tap() }
        app.buttons["Today"].firstMatch.tap()
        let row = app.staticTexts["Zone check"].firstMatch
        for _ in 0..<4 where !row.exists { app.swipeUp() }
        save(app, "zone-2-new-york")
        XCTAssertTrue(row.exists, "The task isn't on today in New York")
        XCTAssertTrue(app.staticTexts[time].exists, "\(time) changed in New York")
        if row.exists {
            row.swipeLeft()
            if app.buttons["Delete"].waitForExistence(timeout: 2) { app.buttons["Delete"].tap() }
            if app.buttons["Delete task"].waitForExistence(timeout: 2) { app.buttons["Delete task"].tap() }
        }
    }

    /// On a clean simulator: chooses the theme in `TEMPO_THEME` (default "Pink") in the real app, adds a task, adds
    /// the Now, Day, Timer and Focus widgets through the dock's edit menu, and photographs Home Screen pages 1–3
    /// (SPEC F-27: widgets use the theme color). The task stays for the photos and is deleted at the end.
    @MainActor
    func testThemedWidgetsOnHomeScreen() {
        let theme = ProcessInfo.processInfo.environment["TEMPO_THEME"] ?? "Pink"
        let app = XCUIApplication()
        app.launch()
        finishGuideIfShown(app)
        if app.buttons["Not now"].waitForExistence(timeout: 2) { app.buttons["Not now"].tap() }
        app.buttons["Settings"].firstMatch.tap()
        let swatch = app.buttons[theme]
        for _ in 0..<4 where !swatch.isHittable { app.swipeUp() }
        swatch.tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Add task"].firstMatch.tap()
        let title = app.textFields["Title"]
        title.tap()
        title.typeText("Theme check")
        app.buttons["Anytime"].tap()
        app.buttons["Save"].tap()
        sleep(1)

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        // Gallery positions: Timer 0, Day 1, Focus 2, Now 3.
        for (index, swipes) in [3, 1, 0, 2].enumerated() {
            XCUIDevice.shared.press(.home)
            sleep(1)
            XCUIDevice.shared.press(.home)
            sleep(1)
            // The empty end of the dock opens the edit menu without touching an icon or widget.
            springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.82, dy: 0.935)).press(forDuration: 2)
            if springboard.buttons["Edit"].waitForExistence(timeout: 3) { springboard.buttons["Edit"].tap() }
            if springboard.buttons["Add Widget"].firstMatch.waitForExistence(timeout: 3) {
                springboard.buttons["Add Widget"].firstMatch.tap()
            }
            let search = springboard.searchFields.firstMatch
            guard search.waitForExistence(timeout: 3) else {
                saveScreen("themed-x-no-gallery-\(index)")
                return
            }
            search.tap()
            search.typeText("Tempo")
            // A newly installed extension can take a moment to show up in the gallery.
            let tempo = springboard.staticTexts["Tempo"].firstMatch
            guard tempo.waitForExistence(timeout: 15) else {
                saveScreen("themed-x-not-in-gallery-\(index)")
                return
            }
            tempo.tap()
            sleep(2)
            for _ in 0..<swipes {
                springboard.swipeLeft()
                sleep(1)
            }
            let add = springboard.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Widget'"))
                .allElementsBoundByIndex.last { $0.isHittable }
            add?.tap()
            sleep(2)
            if springboard.buttons["Done"].firstMatch.waitForExistence(timeout: 2) {
                springboard.buttons["Done"].firstMatch.tap()
            }
            sleep(1)
        }
        XCUIDevice.shared.press(.home)
        sleep(1)
        XCUIDevice.shared.press(.home)
        sleep(4)
        for page in 1...3 {
            saveScreen("themed-\(theme.lowercased())-\(page)")
            springboard.swipeLeft()
            sleep(1)
        }

        app.activate()
        app.buttons["Today"].firstMatch.tap()
        let row = app.staticTexts["Theme check"].firstMatch
        if row.waitForExistence(timeout: 3) {
            row.swipeLeft()
            if app.buttons["Delete"].waitForExistence(timeout: 2) { app.buttons["Delete"].tap() }
            if app.buttons["Delete task"].waitForExistence(timeout: 2) { app.buttons["Delete task"].tap() }
        }
    }

    /// Photographs each Home Screen page, to plan where widgets can go.
    @MainActor
    func testHomeScreenPages() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCUIDevice.shared.press(.home)
        sleep(1)
        XCUIDevice.shared.press(.home)
        sleep(1)
        for page in 1...3 {
            save(springboard, "page-\(page)")
            springboard.swipeLeft()
            sleep(1)
        }
    }

    /// Adds the Focus widget (medium) with two real tasks (one in the part in progress, one at Night),
    /// photographs it, then deletes the tasks. Run in the afternoon or evening.
    @MainActor
    func testFocusWidgetOnHomeScreen() {
        let app = XCUIApplication()
        app.launch()
        finishGuideIfShown(app)
        if app.buttons["Not now"].waitForExistence(timeout: 2) { app.buttons["Not now"].tap() }
        for (name, part) in [("Focus check", nil), ("Focus later", "Night")] as [(String, String?)] {
            app.tabBars.buttons["Today"].tap()
            app.buttons["Add task"].tap()
            let title = app.textFields["Title"]
            title.tap()
            title.typeText(name)
            if let part { app.buttons[part].tap() }
            app.buttons["Save"].tap()
            sleep(1)
        }
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCUIDevice.shared.press(.home)
        sleep(1)
        XCUIDevice.shared.press(.home)
        sleep(1)
        springboard.swipeLeft()
        sleep(1)
        springboard.swipeLeft()
        sleep(1)
        // The empty end of the dock: a long press there opens the edit menu without touching a widget.
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.82, dy: 0.935)).press(forDuration: 2)
        sleep(1)
        save(springboard, "focus-0-menu")
        if springboard.buttons["Edit"].waitForExistence(timeout: 3) { springboard.buttons["Edit"].tap() }
        sleep(1)
        if springboard.buttons["Add Widget"].firstMatch.waitForExistence(timeout: 3) {
            springboard.buttons["Add Widget"].firstMatch.tap()
        }
        sleep(2)
        let search = springboard.searchFields.firstMatch
        guard search.waitForExistence(timeout: 3) else {
            save(springboard, "focus-x-no-gallery")
            return
        }
        search.tap()
        search.typeText("Tempo")
        sleep(1)
        springboard.staticTexts["Tempo"].firstMatch.tap()
        sleep(2)
        springboard.swipeLeft()
        sleep(1)
        springboard.swipeLeft()
        sleep(2)
        save(springboard, "focus-1-gallery")
        let candidates = springboard.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Widget'"))
            .allElementsBoundByIndex
        if let button = candidates.last(where: { $0.isHittable }) {
            button.tap()
        } else {
            springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.905)).tap()
        }
        sleep(2)
        if springboard.buttons["Done"].firstMatch.waitForExistence(timeout: 2) {
            springboard.buttons["Done"].firstMatch.tap()
        }
        sleep(3)
        save(springboard, "focus-2-home")

        app.activate()
        app.tabBars.buttons["Today"].tap()
        for name in ["Focus check", "Focus later"] {
            let row = app.staticTexts[name].firstMatch
            guard row.waitForExistence(timeout: 3) else { continue }
            row.swipeLeft()
            if app.buttons["Delete"].waitForExistence(timeout: 2) { app.buttons["Delete"].tap() }
            if app.buttons["Delete task"].waitForExistence(timeout: 2) { app.buttons["Delete task"].tap() }
            sleep(1)
        }
    }
    /// Adds both Lock Screen widgets next to a real task and photographs them, taps the rectangular one, then
    /// photographs them again with "Hide task names on the Lock Screen" on, and cleans up. The iOS 27 simulator
    /// can't edit the Lock Screen, so run this on iOS 26.5. A simulator can't have a passcode, so it never counts as
    /// locked and names stay visible there.
    @MainActor
    func testLockScreenWidgets() {
        let app = XCUIApplication()
        app.launch()
        finishGuideIfShown(app)
        if app.buttons["Not now"].waitForExistence(timeout: 2) { app.buttons["Not now"].tap() }
        app.buttons["Today"].firstMatch.tap()
        app.buttons["Add task"].tap()
        let title = app.textFields["Title"]
        title.tap()
        title.typeText("Lock check")
        app.buttons["Save"].tap()
        sleep(1)

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        lockAndWake()
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62)).press(forDuration: 2)
        sleep(2)
        springboard.buttons["posterboard-customize-button"].tap()
        sleep(2)
        let widgetArea = springboard.buttons["grouped-widgets-reticle-view"].firstMatch
        _ = widgetArea.waitForExistence(timeout: 5)
        if !springboard.buttons["com.akumatech.tempo.widgets:LockScreenWidget"].exists {
            widgetArea.tap()
            sleep(2)
            let tempo = springboard.cells["Tempo"]
            for _ in 0..<4 where !tempo.isHittable {
                springboard.cells.element(boundBy: 2).swipeUp()
                sleep(1)
            }
            tempo.tap()
            sleep(2)
            springboard.buttons["Tempo, Next task"].tap()
            sleep(2)
            // "close" on iPhone, "Close" on iPad.
            let close = springboard.buttons.matching(NSPredicate(format: "label ==[c] 'close'")).firstMatch
            if close.exists { close.tap() }
            sleep(1)
            dismissSheet(springboard)
        }
        let inline = springboard.buttons["inline-widget-reticle-view"]
        if inline.waitForExistence(timeout: 3) && !inline.label.contains("Tempo") {
            inline.tap()
            sleep(2)
            let choice = springboard.cells.matching(NSPredicate(format: "label BEGINSWITH 'Tempo'")).firstMatch
            for _ in 0..<6 where !choice.isHittable {
                springboard.cells.element(boundBy: 1).swipeUp()
                sleep(1)
            }
            choice.tap()
            sleep(2)
            dismissSheet(springboard)
        }
        save(springboard, "lock-1-editor")
        // On iPad the inline chooser is a popover; a tap beside it closes it.
        if springboard.staticTexts["Choose Widget"].exists {
            springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5)).tap()
            sleep(1)
        }
        springboard.buttons["editing-done"].tap()
        sleep(2)
        let poster = springboard.cells.matching(NSPredicate(format: "identifier BEGINSWITH 'posterboard-posteruuid'"))
            .firstMatch
        if poster.exists { poster.tap() }
        sleep(1)

        lockAndWake()
        sleep(3)
        save(springboard, "lock-2-locked")
        // The rectangular widget: the left of the widget row, low on an iPhone and lower still on an iPad.
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        springboard.coordinate(withNormalizedOffset: isPad ? CGVector(dx: 0.4, dy: 0.86) : CGVector(dx: 0.25, dy: 0.82))
            .tap()
        sleep(3)
        save(app, "lock-3-opened")

        setHideTaskNames(app, true)
        lockAndWake()
        sleep(3)
        save(springboard, "lock-4-names-hidden")
        XCUIDevice.shared.press(.home)
        sleep(1)
        app.activate()
        setHideTaskNames(app, false)

        app.buttons["Today"].firstMatch.tap()
        // Earlier interrupted runs may have left tasks behind too.
        for _ in 0..<10 {
            let row = app.staticTexts["Lock check"].firstMatch
            guard row.waitForExistence(timeout: 3) else { break }
            row.swipeLeft()
            if app.buttons["Delete"].waitForExistence(timeout: 2) { app.buttons["Delete"].tap() }
            if app.buttons["Delete task"].waitForExistence(timeout: 2) { app.buttons["Delete task"].tap() }
            sleep(1)
        }
    }

    /// The real app shows the first-launch guide until it has been finished once on the simulator.
    @MainActor
    private func finishGuideIfShown(_ app: XCUIApplication) {
        guard app.buttons["Skip"].waitForExistence(timeout: 2) else { return }
        app.buttons["Skip"].tap()
        app.buttons["Next"].tap()
        app.buttons["Not now"].tap()
        sleep(1)
    }

    @MainActor
    private func lockAndWake() {
        XCUIDevice.shared.perform(NSSelectorFromString("pressLockButton"))
        sleep(2)
        XCUIDevice.shared.press(.home)
        sleep(2)
    }

    /// Drags the Lock Screen editor's widget sheet down and away.
    @MainActor
    private func dismissSheet(_ springboard: XCUIApplication) {
        let grabber = springboard.buttons["Sheet Grabber"]
        guard grabber.exists else { return }
        grabber.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(
            forDuration: 0.2, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98)))
        sleep(2)
    }

    @MainActor
    private func setHideTaskNames(_ app: XCUIApplication, _ on: Bool) {
        app.buttons["Settings"].firstMatch.tap()
        let toggle = app.switches["Hide task names on the Lock Screen"].firstMatch
        for _ in 0..<3 where !toggle.isHittable { app.swipeUp() }
        if (toggle.value as? String == "1") != on {
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        }
        sleep(1)
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }
}
