/// Minutes logged against a goal over some range of days (SPEC §5.5).
public struct GoalProgress: Hashable, Sendable {
    public let minutes: Int
    public let goal: Int

    public init(minutes: Int, goal: Int) {
        self.minutes = minutes
        self.goal = goal
    }

    /// The goal is met when the total reaches it.
    public var isMet: Bool { minutes >= goal }
}
