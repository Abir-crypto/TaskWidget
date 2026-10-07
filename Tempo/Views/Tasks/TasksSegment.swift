import SwiftUI

/// The Tasks tab's two lists (SPEC F-11). Stored by raw value, so the last choice survives a restart.
enum TasksSegment: String, CaseIterable {
    case habits
    case oneTime

    var title: LocalizedStringKey {
        switch self {
        case .habits: "Habits"
        case .oneTime: "One-time"
        }
    }
}
