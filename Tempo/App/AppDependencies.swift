import Core
import Foundation

/// The app's managers, created once at launch and shared by every screen.
@MainActor
final class AppDependencies {
    let clock: any Clock
    let store: any TaskStore
    let deviceState: DeviceState
    let refresh: RefreshManager
    let settings: SettingsManager
    let tasks: TaskManager

    init(clock: any Clock, store: any TaskStore, deviceState: DeviceState, widgets: any WidgetReloading) {
        self.clock = clock
        self.store = store
        self.deviceState = deviceState
        self.refresh = RefreshManager(widgets: widgets)
        self.settings = SettingsManager(store: store, refresh: refresh)
        self.tasks = TaskManager(store: store, clock: clock, refresh: refresh)
    }

    /// The real dependencies: the shared App Group store, the system clock and WidgetKit.
    static func live() throws -> AppDependencies {
        let clock = SystemClock()
        let container = try StoreFactory.shared.get()
        return AppDependencies(
            clock: clock,
            store: SwiftDataTaskStore(container: container, clock: clock),
            deviceState: .shared,
            widgets: WidgetManager()
        )
    }

    /// Runs once at launch: makes sure the settings row exists (SPEC §4.5).
    func prepare() {
        do {
            try settings.loadOrCreate()
        } catch {
            Log.settings.error("Couldn't create the settings row: \(error)")
        }
    }
}
