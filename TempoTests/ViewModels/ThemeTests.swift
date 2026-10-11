import Core
import Foundation
import SwiftUI
import Testing

@testable import Tempo

/// SPEC T-33: the theme color reaches the app's root, the widgets' snapshot, and comes back from the color picker.
@MainActor
struct ThemeTests {
    private let clock = TestEnvironment.clock()
    private let store: SwiftDataTaskStore
    private let widgets = WidgetReloadCounter()
    private let settings: SettingsManager

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        settings = SettingsManager(store: store, refresh: RefreshManager(widgets: widgets))
    }

    private func choose(_ color: ThemeColor) throws {
        var value = try settings.loadOrCreate()
        value.tintColor = color
        try settings.update(value)
    }

    @Test func theRootShowsBlueUntilAColorIsChosen() throws {
        let root = RootViewModel(
            missed: MissedManager(
                tasks: TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: widgets)),
                deviceState: TestEnvironment.deviceState(), clock: clock), settings: settings)
        root.load()
        #expect(root.theme == .preset(.blue))
        try choose(.preset(.purple))
        root.load()
        #expect(root.theme == .preset(.purple))
    }

    @Test func choosingAColorRefreshesTheWidgetsWithIt() async throws {
        try choose(.custom(red: 255, green: 99, blue: 71))
        #expect(await eventually { widgets.count > 0 })
        let snapshot = try SnapshotLoader.load(store: store, deviceState: TestEnvironment.deviceState(), clock: clock)
        #expect(snapshot.core.settings.tintColor == .custom(red: 255, green: 99, blue: 71))
    }

    @Test func aPickedColorBecomesItsSRGBComponents() {
        let picked = Color(.sRGB, red: 30 / 255, green: 144 / 255, blue: 1)
        #expect(ThemePicker.themeColor(from: picked) == .custom(red: 30, green: 144, blue: 255))
        #expect(
            ThemePicker.themeColor(from: Color(.sRGB, red: 0, green: 0, blue: 0)) == .custom(red: 0, green: 0, blue: 0))
    }

    @Test func everyPresetHasANameAndAColor() {
        for preset in ThemePreset.allCases {
            #expect(!preset.title.isEmpty)
        }
        #expect(ThemeColor.preset(.blue).color == .blue)
        #expect(ThemeColor.custom(red: 255, green: 0, blue: 0).color == Color(.sRGB, red: 1, green: 0, blue: 0))
    }
}
