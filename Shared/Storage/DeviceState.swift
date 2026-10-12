import Core
import Foundation

/// State that stays on this device and is never synced (SPEC §4.6): the timer, the missed popup's seen list, the
/// pending open action, whether the first-launch guide was finished, snoozed reminders, whether the Add a widget card
/// was closed, and the cached Pro entitlement. Stored as JSON in the App Group's `UserDefaults`, so the app and the
/// widget extension share it (ios.md §6).
final class DeviceState: @unchecked Sendable {
    // `UserDefaults` is thread-safe; it's the only stored property.
    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    /// The App Group's shared defaults. Falls back to the app's own defaults if the group is unavailable.
    static let shared: DeviceState = {
        guard let defaults = UserDefaults(suiteName: StoreFactory.appGroup) else {
            Log.deviceState.error("App Group defaults unavailable; using standard defaults")
            return DeviceState(defaults: .standard)
        }
        return DeviceState(defaults: defaults)
    }()

    enum Key: String, CaseIterable {
        case timer = "deviceState.timer"
        case missedSeen = "deviceState.missedSeen"
        case pendingOpenAction = "deviceState.pendingOpenAction"
        case guideCompleted = "deviceState.guideCompleted"
        case snoozes = "deviceState.snoozes"
        case addWidgetCardClosed = "deviceState.addWidgetCardClosed"
        case proEntitlement = "deviceState.proEntitlement"
    }

    /// The one timer, or `nil` when idle.
    var timer: TimerState? {
        get { read(TimerState.self, for: .timer) }
        set { write(newValue, for: .timer) }
    }

    /// The missed tasks the popup has already shown.
    var missedSeen: MissedSeenList? {
        get { read(MissedSeenList.self, for: .missedSeen) }
        set { write(newValue, for: .missedSeen) }
    }

    /// Written by widget buttons that open the app; read and cleared by the app.
    var pendingOpenAction: PendingOpenAction? {
        get { read(PendingOpenAction.self, for: .pendingOpenAction) }
        set { write(newValue, for: .pendingOpenAction) }
    }

    /// The first-launch guide was finished; it never shows on its own again (SPEC F-23).
    var guideCompleted: Bool {
        get { defaults.bool(forKey: Key.guideCompleted.rawValue) }
        set { defaults.set(newValue, forKey: Key.guideCompleted.rawValue) }
    }

    /// Snoozed reminders. Only the list's own day counts, so snoozes clear when the day changes (SPEC F-07).
    var snoozes: SnoozeList? {
        get { read(SnoozeList.self, for: .snoozes) }
        set { write(newValue, for: .snoozes) }
    }

    /// The Add a widget card on Today was closed; it doesn't come back (SPEC F-10).
    var addWidgetCardClosed: Bool {
        get { defaults.bool(forKey: Key.addWidgetCardClosed.rawValue) }
        set { defaults.set(newValue, forKey: Key.addWidgetCardClosed.rawValue) }
    }

    /// Tempo Pro as the store last confirmed it, so it works offline and the widgets can read it (SPEC F-34).
    var proEntitlement: ProEntitlement? {
        get { read(ProEntitlement.self, for: .proEntitlement) }
        set { write(newValue, for: .proEntitlement) }
    }

    /// Removes every device-only value.
    func reset() {
        for key in Key.allCases {
            defaults.removeObject(forKey: key.rawValue)
        }
    }

    private func read<Value: Decodable>(_ type: Value.Type, for key: Key) -> Value? {
        guard let data = defaults.data(forKey: key.rawValue) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            Log.deviceState.error("Couldn't decode \(key.rawValue, privacy: .public): \(error)")
            return nil
        }
    }

    private func write<Value: Encodable>(_ value: Value?, for key: Key) {
        guard let value else {
            defaults.removeObject(forKey: key.rawValue)
            return
        }
        do {
            defaults.set(try JSONEncoder().encode(value), forKey: key.rawValue)
        } catch {
            Log.deviceState.error("Couldn't encode \(key.rawValue, privacy: .public): \(error)")
        }
    }
}
