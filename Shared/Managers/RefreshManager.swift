import Foundation

/// Runs after every write so every view of the data catches up (ios.md §4, rule 2).
///
/// It reloads every widget. Notification rebuilding joins it in T-21.
@MainActor
final class RefreshManager {
    /// The app batches bursts of writes into one refresh.
    static let debounce: Duration = .milliseconds(500)

    private let widgets: any WidgetReloading
    private var pending: Task<Void, Never>?

    init(widgets: any WidgetReloading) {
        self.widgets = widgets
    }

    /// Call after every write in the app. Refreshes once, 0.5 s after the last call.
    func afterChange() {
        pending?.cancel()
        pending = Task { [weak self] in
            try? await Task.sleep(for: Self.debounce)
            guard !Task.isCancelled else { return }
            self?.refreshNow()
        }
    }

    /// Refreshes immediately. App Intents use this, because their process may end right after.
    func refreshNow() {
        pending?.cancel()
        pending = nil
        Log.refresh.debug("Reloading widgets")
        widgets.reloadAll()
    }
}
