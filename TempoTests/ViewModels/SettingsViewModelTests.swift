import Core
import Foundation
import Testing

@testable import Tempo

@MainActor
struct SettingsViewModelTests {
    private let clock = TestEnvironment.clock()

    private func model(store: any TaskStore, permission: NotificationPermission = .allowed) -> SettingsViewModel {
        let manager = SettingsManager(store: store, refresh: RefreshManager(widgets: WidgetReloadCounter()))
        return SettingsViewModel(manager: manager, notifications: FixedNotificationScheduler(permission: permission))
    }

    @Test func loadsTheDefaultsAndThePermission() async throws {
        let model = model(store: try TestEnvironment.store(clock: clock))
        await model.load()
        #expect(model.settings.parts == .defaults)
        #expect(model.settings.recapMinute == 1410)
        #expect(model.permission == .allowed)
    }

    @Test func everySettingIsSavedAndSurvivesARestart() async throws {
        let url = try StoreFactory.storeURL(fileName: "Tempo-settings-\(UUID().uuidString).store")
        defer {
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(at: URL(filePath: url.path() + suffix))
            }
        }
        let first = model(store: SwiftDataTaskStore(container: try StoreFactory.make(url: url), clock: clock))
        await first.load()
        first.setStart(of: .morning, to: 420)
        first.setStart(of: .night, to: 1320)
        first.update { settings in
            settings.partStartSummaries = [.evening, .night]
            settings.notifyEndingSoon = false
            settings.endingSoonLead = 45
            settings.notifyFixed = false
            settings.fixedLead = 15
            settings.notifyRecap = false
            settings.recapMinute = 1425
            settings.notifyTimer = false
            settings.timerAlertMinutes = 180
            settings.hideLockScreenTitles = true
            settings.tintColor = .custom(red: 30, green: 144, blue: 255)
            settings.appearance = .light
            settings.missedStyle = .strict
        }

        // A new container on the same file stands in for relaunching the app.
        let second = model(store: SwiftDataTaskStore(container: try StoreFactory.make(url: url), clock: clock))
        await second.load()
        let saved = second.settings
        #expect(saved.parts.morningStart == 420)
        #expect(saved.parts.nightStart == 1320)
        #expect(saved.partStartSummaries == [.evening, .night])
        #expect(saved.missedStyle == .strict)
        #expect(!saved.notifyEndingSoon && !saved.notifyFixed)
        #expect(!saved.notifyRecap && !saved.notifyTimer)
        #expect(saved.endingSoonLead == 45)
        #expect(saved.fixedLead == 15)
        #expect(saved.recapMinute == 1425)
        #expect(saved.timerAlertMinutes == 180)
        #expect(saved.hideLockScreenTitles)
        #expect(saved.tintColor == .custom(red: 30, green: 144, blue: 255))
        #expect(saved.appearance == .light)
    }

    @Test func invalidPartTimesAreNotSaved() async throws {
        let store = try TestEnvironment.store(clock: clock)
        let model = model(store: store)
        await model.load()
        model.setStart(of: .noon, to: 1200)  // after Evening's start
        model.setStart(of: .morning, to: 365)  // off the quarter hour
        try await Task.sleep(for: .milliseconds(100))
        #expect(try store.settings()?.parts == .defaults)
        #expect(model.settings.parts == .defaults)
    }

    @Test func pickersOnlyOfferValidStarts() async throws {
        let model = model(store: try TestEnvironment.store(clock: clock))
        await model.load()
        #expect(model.allowedStarts(for: .morning) == 0...690)
        #expect(model.allowedStarts(for: .noon) == 390...990)
        #expect(model.allowedStarts(for: .evening) == 750...1230)
        #expect(model.allowedStarts(for: .night) == 1050...1410)
    }

    @Test func movingNightPastTheRecapCarriesTheRecap() async throws {
        let model = model(store: try TestEnvironment.store(clock: clock))
        await model.load()
        model.update { $0.recapMinute = 1290 }
        model.setStart(of: .night, to: 1350)
        #expect(model.settings.parts.nightStart == 1350)
        #expect(model.settings.recapMinute == 1350)
    }

    @Test func permissionCanBeRequestedWhenNotAskedYet() async throws {
        let model = model(store: try TestEnvironment.store(clock: clock), permission: .notDetermined)
        await model.load()
        #expect(model.permission == .notDetermined)
        await model.requestPermission()
        #expect(model.permission == .allowed)
    }

    @Test func showsWhenNotificationsAreOff() async throws {
        let model = model(store: try TestEnvironment.store(clock: clock), permission: .denied)
        await model.load()
        #expect(model.permission == .denied)
    }
}
