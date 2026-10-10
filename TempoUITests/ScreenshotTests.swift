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
        app.buttons["Add task"].tap()
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
        for _ in 0..<3 where !springboard.staticTexts["Widget check"].firstMatch.exists { springboard.swipeLeft() }
        sleep(3)
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
        for _ in 0..<3 where !springboard.icons["Contacts"].exists || !springboard.icons["Contacts"].isHittable {
            springboard.swipeLeft()
        }
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
        app.tabBars.buttons["Today"].tap()
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
        if !springboard.buttons["com.applab.tempo.widgets:LockScreenWidget"].exists {
            springboard.buttons["grouped-widgets-reticle-view"].firstMatch.tap()
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
            if springboard.buttons["close"].exists { springboard.buttons["close"].tap() }
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
        springboard.buttons["editing-done"].tap()
        sleep(2)
        let poster = springboard.cells.matching(NSPredicate(format: "identifier BEGINSWITH 'posterboard-posteruuid'"))
            .firstMatch
        if poster.exists { poster.tap() }
        sleep(1)

        lockAndWake()
        sleep(3)
        save(springboard, "lock-2-locked")
        // The rectangular widget, below the clock on the left.
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.82)).tap()
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

        app.tabBars.buttons["Today"].tap()
        let row = app.staticTexts["Lock check"].firstMatch
        if row.waitForExistence(timeout: 3) {
            row.swipeLeft()
            if app.buttons["Delete"].waitForExistence(timeout: 2) { app.buttons["Delete"].tap() }
            if app.buttons["Delete task"].waitForExistence(timeout: 2) { app.buttons["Delete task"].tap() }
        }
        sleep(1)
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
