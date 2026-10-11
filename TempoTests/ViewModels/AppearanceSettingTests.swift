import Core
import Foundation
import Testing
import UIKit

@testable import Tempo

/// SPEC T-34: the appearance reaches the app's root and becomes the windows' interface style.
@MainActor
struct AppearanceSettingTests {
    private let clock = TestEnvironment.clock()
    private let store: SwiftDataTaskStore
    private let widgets = WidgetReloadCounter()
    private let settings: SettingsManager

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        settings = SettingsManager(store: store, refresh: RefreshManager(widgets: widgets))
    }

    private func root() -> RootViewModel {
        RootViewModel(
            missed: MissedManager(
                tasks: TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: widgets)),
                deviceState: TestEnvironment.deviceState(), clock: clock), settings: settings)
    }

    @Test func theRootFollowsTheSystemUntilAnAppearanceIsChosen() throws {
        let root = root()
        root.load()
        #expect(root.appearance == .system)
        for appearance in [Appearance.dark, .light, .system] {
            var value = try settings.loadOrCreate()
            value.appearance = appearance
            try settings.update(value)
            root.load()
            #expect(root.appearance == appearance)
        }
    }

    @Test func choosingAnAppearanceKeepsTheThemeColor() throws {
        var value = try settings.loadOrCreate()
        value.tintColor = .preset(.green)
        try settings.update(value)
        value.appearance = .dark
        try settings.update(value)
        let root = root()
        root.load()
        #expect(root.theme == .preset(.green))
        #expect(root.appearance == .dark)
    }

    @Test func systemLeavesTheStyleToTheDevice() {
        #expect(Appearance.system.userInterfaceStyle == .unspecified)
        #expect(Appearance.dark.userInterfaceStyle == .dark)
        #expect(Appearance.light.userInterfaceStyle == .light)
    }

    @Test func everyChoiceHasAName() {
        #expect(Appearance.allCases.map(\.title).allSatisfy { !$0.isEmpty })
        #expect(Set(Appearance.allCases.map(\.title)).count == 3)
    }
}
