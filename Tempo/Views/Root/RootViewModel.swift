import Foundation
import Observation

/// State for the tab layout: the Missed tab's badge.
@Observable
@MainActor
final class RootViewModel {
    private(set) var missedCount = 0

    private let missed: MissedManager

    init(missed: MissedManager) {
        self.missed = missed
    }

    func load() {
        missedCount = missed.missedTodayCount()
    }
}
