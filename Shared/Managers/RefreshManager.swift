import Foundation
import Observation

/// Runs after every write so every view of the data catches up (ios.md §4, rule 2).
///
/// It reloads every widget and rebuilds the pending notifications. Screens watch `revision` and reload from
/// storage when it changes.
@Observable
@MainActor
final class RefreshManager {
    /// The app batches bursts of writes into one refresh.
    static let debounce: Duration = .milliseconds(500)

    /// Goes up by one on every change, straight away, so open screens reload without waiting for the debounce.
    private(set) var revision = 0

    @ObservationIgnored private let widgets: any WidgetReloading
    @ObservationIgnored private var pending: Task<Void, Never>?
    /// Rebuilds notifications after each refresh. Set once the reminder manager exists.
    @ObservationIgnored var reminders: ReminderManager?
    /// Keeps the timer's Live Activity in step (SPEC F-31). Set only for the real app, so tests never start one.
    @ObservationIgnored var timerActivity: TimerActivityManager?

    init(widgets: any WidgetReloading) {
        self.widgets = widgets
    }

    /// Call after every write in the app. Refreshes once, 0.5 s after the last call.
    func afterChange() {
        revision += 1
        pending?.cancel()
        pending = Task { [weak self] in
            try? await Task.sleep(for: Self.debounce)
            guard !Task.isCancelled else { return }
            self?.refreshNow()
        }
    }

    /// Tells open screens to reload without a write of their own, for example when the app becomes active
    /// after a widget changed something.
    func dataMayHaveChanged() {
        revision += 1
        if let timerActivity {
            Task { await timerActivity.sync() }
        }
    }

    /// Refreshes immediately. App Intents use this, because their process may end right after.
    func refreshNow() {
        pending?.cancel()
        pending = nil
        Log.refresh.debug("Reloading widgets and rebuilding notifications")
        widgets.reloadAll()
        if let reminders {
            Task { await reminders.rebuild() }
        }
        if let timerActivity {
            Task { await timerActivity.sync() }
        }
    }

    /// Refreshes immediately and waits for the notifications to be rebuilt. App Intents use this, because the
    /// extension's process may end as soon as the intent returns.
    func refreshNowAndWait() async {
        pending?.cancel()
        pending = nil
        widgets.reloadAll()
        await reminders?.rebuild()
        await timerActivity?.sync()
    }
}
