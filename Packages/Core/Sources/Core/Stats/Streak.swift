/// A habit's current and best streak of done scheduled days (SPEC §5.7).
public struct Streak: Hashable, Sendable {
    public let current: Int
    public let best: Int

    public init(current: Int, best: Int) {
        self.current = current
        self.best = best
    }

    public static let zero = Streak(current: 0, best: 0)
}
