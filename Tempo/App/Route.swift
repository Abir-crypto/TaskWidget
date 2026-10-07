import Foundation

/// Screens pushed onto a tab's navigation stack.
enum Route: Hashable {
    /// Habit detail (SPEC F-13).
    case habit(UUID)
}
