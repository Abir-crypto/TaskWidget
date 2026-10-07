import Foundation

@testable import Tempo

/// Counts widget reloads instead of calling WidgetKit.
final class WidgetReloadCounter: WidgetReloading, @unchecked Sendable {
    private let lock = NSLock()
    private var reloads = 0

    var count: Int { lock.withLock { reloads } }

    func reloadAll() {
        lock.withLock { reloads += 1 }
    }
}
