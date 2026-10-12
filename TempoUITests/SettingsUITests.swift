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

    /// SPEC T-34: System, Dark and Light, with the current choice marked. Dark and Light change the screen and what's
    /// presented over it, whatever the simulator's own mode.
    @MainActor
    func testAppearanceChoices() {
        let app = UITestApp.launch()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        let system = app.buttons["System"]
        for _ in 0..<4 where !system.isHittable { app.swipeUp() }
        XCTAssertTrue(system.isSelected)
        XCTAssertTrue(app.buttons["Dark"].exists && app.buttons["Light"].exists)

        app.buttons["Dark"].tap()
        XCTAssertTrue(app.buttons["Dark"].waitForSelection())
        XCTAssertFalse(system.isSelected)
        XCTAssertLessThan(brightness(of: app), 0.3, "Settings isn't dark")
        let howToUse = app.buttons["How to use"]
        for _ in 0..<4 where !howToUse.isHittable { app.swipeUp() }
        howToUse.tap()
        XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 3))
        XCTAssertLessThan(brightness(of: app), 0.3, "The guide isn't dark")
        app.buttons["Done"].tap()

        let light = app.buttons["Light"]
        for _ in 0..<4 where !light.isHittable { app.swipeDown() }
        light.tap()
        XCTAssertTrue(light.waitForSelection())
        XCTAssertGreaterThan(brightness(of: app), 0.7, "Settings isn't light")

        system.tap()
        XCTAssertTrue(system.waitForSelection())
    }

    /// The app's average brightness on screen, from 0 (black) to 1 (white), after any transition has finished.
    @MainActor
    private func brightness(of app: XCUIApplication) -> Double {
        sleep(1)
        guard let image = app.screenshot().image.cgImage else { return -1 }
        let side = 32
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        guard
            let context = CGContext(
                data: &pixels, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return -1 }
        context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
        var total = 0
        for index in stride(from: 0, to: pixels.count, by: 4) {
            total += Int(pixels[index]) + Int(pixels[index + 1]) + Int(pixels[index + 2])
        }
        return Double(total) / Double(side * side * 3 * 255)
    }

    @MainActor
    func testEverySettingIsPresent() {
        let app = UITestApp.launch()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        for part in ["Morning", "Afternoon", "Evening", "Night"] {
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
