import SwiftUI

/// History's two lists (SPEC F-12).
enum HistorySegment: String, CaseIterable {
    case oneTime
    case habits

    var title: LocalizedStringKey {
        switch self {
        case .oneTime: "One-time"
        case .habits: "Habits"
        }
    }
}
