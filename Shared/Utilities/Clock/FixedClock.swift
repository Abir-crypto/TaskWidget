import Foundation

/// A clock that stays where it's set, for previews and tests.
final class FixedClock: Clock, @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date
    let calendar: Calendar

    init(_ now: Date, calendar: Calendar) {
        self.current = now
        self.calendar = calendar
    }

    var now: Date {
        get { lock.withLock { current } }
        set { lock.withLock { current = newValue } }
    }

    /// Moves the clock forward.
    func advance(by seconds: TimeInterval) {
        lock.withLock { current = current.addingTimeInterval(seconds) }
    }
}
