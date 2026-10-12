import Foundation

/// Whether Tempo Pro is unlocked, as the store last confirmed it (SPEC F-34, §4.6). Cached on the device so it works
/// offline and the widgets can read it. Never synced.
public struct ProEntitlement: Hashable, Codable, Sendable {
    public var isUnlocked: Bool
    /// When the store last confirmed it.
    public var confirmedAt: Date

    public init(isUnlocked: Bool, confirmedAt: Date) {
        self.isUnlocked = isUnlocked
        self.confirmedAt = confirmedAt
    }
}
