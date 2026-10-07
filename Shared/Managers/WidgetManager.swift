import WidgetKit

/// Reloads every widget's timeline through WidgetKit.
struct WidgetManager: WidgetReloading {
    func reloadAll() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
