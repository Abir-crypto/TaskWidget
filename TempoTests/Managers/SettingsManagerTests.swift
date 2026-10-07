import Core
import Foundation
import Testing

@testable import Tempo

@MainActor
struct SettingsManagerTests {
    private let clock = TestEnvironment.clock()
    private let store: SwiftDataTaskStore
    private let widgets = WidgetReloadCounter()
    private let manager: SettingsManager

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        manager = SettingsManager(store: store, refresh: RefreshManager(widgets: widgets))
    }

    @Test func firstLaunchCreatesTheDefaults() throws {
        #expect(try store.settings() == nil)
        let settings = try manager.loadOrCreate()
        var expected = SettingsValue.defaults
        expected.updatedAt = clock.now
        #expect(settings == expected)
        #expect(try store.settings() == expected)
    }

    @Test func laterLaunchesKeepTheSavedSettings() throws {
        var settings = try manager.loadOrCreate()
        settings.notifyRecap = false
        try manager.update(settings)
        #expect(try manager.loadOrCreate().notifyRecap == false)
    }

    @Test func invalidPartTimesAreRejected() throws {
        var settings = try manager.loadOrCreate()
        settings.parts = settings.parts.setting(.noon, to: 365)
        #expect(throws: SettingsError.invalidParts(.notOnStep(.noon))) {
            try manager.update(settings)
        }
        #expect(try store.settings()?.parts == .defaults)
    }

    @Test func updatesRefreshTheWidgets() async throws {
        var settings = try manager.loadOrCreate()
        settings.hideLockScreenTitles = true
        try manager.update(settings)
        try await Task.sleep(for: .milliseconds(800))
        #expect(widgets.count == 1)
    }
}
