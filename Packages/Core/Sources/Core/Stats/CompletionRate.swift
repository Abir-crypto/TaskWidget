/// Days done out of days counted (SPEC §5.7).
public struct CompletionRate: Hashable, Sendable {
    public let done: Int
    public let counted: Int

    public init(done: Int, counted: Int) {
        self.done = done
        self.counted = counted
    }

    public static let empty = CompletionRate(done: 0, counted: 0)

    /// The rate as a whole percentage, rounded half up, or `nil` ("—") with no counted days (D-062).
    public var percent: Int? {
        guard counted > 0 else { return nil }
        return (done * 200 + counted) / (counted * 2)
    }

    public static func + (lhs: CompletionRate, rhs: CompletionRate) -> CompletionRate {
        CompletionRate(done: lhs.done + rhs.done, counted: lhs.counted + rhs.counted)
    }
}
