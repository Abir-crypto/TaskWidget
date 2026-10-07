/// Reloads widget timelines. A protocol so tests and previews can count reloads instead (ios.md §4).
protocol WidgetReloading: Sendable {
    func reloadAll()
}
