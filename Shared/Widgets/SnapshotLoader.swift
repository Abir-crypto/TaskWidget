import Core
import Foundation

/// Reads a `WidgetSnapshot` from the shared store and device-only state, with a fresh context (ios.md §6).
enum SnapshotLoader {
    /// Reads from the App Group store and device-only state, as the widget extension does.
    static func load(clock: any Clock = SystemClock()) throws -> WidgetSnapshot {
        try load(
            store: SwiftDataTaskStore(container: try StoreFactory.shared.get(), clock: clock), deviceState: .shared,
            clock: clock)
    }

    static func load(store: any TaskStore, deviceState: DeviceState, clock: any Clock) throws -> WidgetSnapshot {
        let core = Snapshot(
            data: try store.loadAll(), settings: try store.settings() ?? .defaults, calendar: clock.calendar)
        let timer = deviceState.timer
        return WidgetSnapshot(
            core: core, timer: timer, timerHabitTitle: timer?.habitID.flatMap { core.engine.task(id: $0)?.title })
    }
}
