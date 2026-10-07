import Foundation
import Observation

/// Runs after every write so every view of the data catches up (ios.md §4, rule 2).
///
/// It reloads every widget. Notification rebuilding joins it in T-21. Screens watch `revision` and reload
/// from storage when it changes.
@Observable
@MainActor
final class RefreshManager {
    /// The app batches bursts of writes into one refresh.
    static let debounce: Duration = .milliseconds(500)

    /// Goes up by one on every change, straight away, so open screens reload without waiting for the debounce.
    private(set) var revision = 0

    @ObservationIgnored private let widgets: any WidgetReloading
    @ObservationIgnored private var pending: Task<Void, Never>?

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
    }

    /// Refreshes immediately. App Intents use this, because their process may end right after.
    func refreshNow() {
        pending?.cancel()
        pending = nil
        Log.refresh.debug("Reloading widgets")
        widgets.reloadAll()
    }
}
