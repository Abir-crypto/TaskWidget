import SwiftUI

/// The four tabs (SPEC F-09).
enum AppTab: Hashable, CaseIterable {
    case today
    case tasks
    case missed
    case stats

    var title: LocalizedStringKey {
        switch self {
        case .today: "Today"
        case .tasks: "Tasks"
        case .missed: "Missed"  // RootView names it after the missed style (SPEC F-30)
        case .stats: "Stats"
        }
    }

    var systemImage: String {
        switch self {
        case .today: "sun.max"
        case .tasks: "checklist"
        case .missed: "exclamationmark.circle"
        case .stats: "chart.bar"
        }
    }
}
