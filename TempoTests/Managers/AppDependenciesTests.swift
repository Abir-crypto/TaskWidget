import Core
import Foundation
import Testing

@testable import Tempo

@MainActor
struct AppDependenciesTests {
    @Test func prepareCreatesTheSettingsRow() throws {
        let clock = TestEnvironment.clock()
        let store = try TestEnvironment.store(clock: clock)
        let dependencies = AppDependencies(
            clock: clock, store: store, deviceState: TestEnvironment.deviceState(),
            notifications: FixedNotificationScheduler(permission: .allowed), widgets: WidgetReloadCounter())
        dependencies.prepare()
        #expect(try store.settings()?.parts == .defaults)
        #expect(try store.settings()?.recapMinute == 1410)
    }
}
