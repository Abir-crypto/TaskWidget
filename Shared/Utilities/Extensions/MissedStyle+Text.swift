import Core
import SwiftUI

/// The words, marks and colors that depend on the missed style (SPEC F-30). Strict is the 1.0 wording in red;
/// Gentle says "Not done" in secondary grey. Statuses, queries and stats never change with the style.
extension MissedStyle {
    /// The choice's name in Settings: "Gentle" or "Strict".
    var title: String {
        switch self {
        case .gentle: String(localized: "Gentle", comment: "Missed style")
        case .strict: String(localized: "Strict", comment: "Missed style")
        }
    }

    /// A missed task's status, and the Missed tab's name: "Missed" or "Not done".
    var statusTitle: String {
        switch self {
        case .strict: String(localized: "Missed")
        case .gentle: String(localized: "Not done")
        }
    }

    /// The status's icon, which always comes with its text or a spoken label: a cross, or a dash.
    var systemImage: String {
        switch self {
        case .strict: "xmark.circle"
        case .gentle: "minus.circle"
        }
    }

    /// Red in Strict, secondary grey in Gentle.
    var color: Color {
        switch self {
        case .strict: .red
        case .gentle: .secondary
        }
    }

    /// Only Strict has the Missed tab's badge and the missed popup.
    var showsBadgeAndPopup: Bool { self == .strict }

    /// "2 missed" or "2 not done".
    func count(_ count: Int) -> String {
        switch self {
        case .strict: String(localized: "\(count) missed")
        case .gentle: String(localized: "\(count) not done")
        }
    }

    /// The Now widget's footer: "2 missed today ›" or "2 not done today ›".
    func todayFooter(_ count: Int) -> String {
        switch self {
        case .strict: String(localized: "\(count) missed today ›")
        case .gentle: String(localized: "\(count) not done today ›")
        }
    }

    /// The end-of-day recap's title (SPEC F-07): "Today: 2 missed, 1 still open" or "Today: 1 still open, 2 not done".
    func recapTitle(missed: Int, open: Int) -> String {
        switch (self, missed, open) {
        case (_, 0, let open): String(localized: "Today: \(open) still open")
        case (.strict, let missed, 0): String(localized: "Today: \(missed) missed")
        case (.strict, let missed, let open): String(localized: "Today: \(missed) missed, \(open) still open")
        case (.gentle, let missed, 0): String(localized: "Today: \(missed) not done")
        case (.gentle, let missed, let open): String(localized: "Today: \(open) still open, \(missed) not done")
        }
    }

    /// A Day widget column for VoiceOver: "2 done, 1 missed, 3 left".
    func columnSummary(done: Int, missed: Int, left: Int) -> String {
        switch self {
        case .strict: String(localized: "\(done) done, \(missed) missed, \(left) left")
        case .gentle: String(localized: "\(done) done, \(missed) not done, \(left) left")
        }
    }

    /// The day strip's spoken description of a day with missed tasks.
    var dayHasMissed: String {
        switch self {
        case .strict: String(localized: "Has missed tasks")
        case .gentle: String(localized: "Has tasks not done")
        }
    }

    /// Stats › Parts of the day: "Most missed: Evening" or "Most often not done: Evening".
    func mostMissed(_ part: String) -> String {
        switch self {
        case .strict: String(localized: "Most missed: \(part)")
        case .gentle: String(localized: "Most often not done: \(part)")
        }
    }

    /// Habit detail's list header: "Recent missed days" or "Recent days not done".
    var recentDaysTitle: String {
        switch self {
        case .strict: String(localized: "Recent missed days")
        case .gentle: String(localized: "Recent days not done")
        }
    }

    /// Habit detail's list when it's empty.
    var noRecentDays: String {
        switch self {
        case .strict: String(localized: "No missed days")
        case .gentle: String(localized: "Nothing left undone")
        }
    }

    /// Missed › Today, empty (SPEC F-24).
    var todayEmpty: String {
        switch self {
        case .strict: String(localized: "You haven't missed a task today")
        case .gentle: String(localized: "Nothing left undone today")
        }
    }

    /// Missed › Earlier, empty (SPEC F-24).
    var earlierEmpty: String {
        switch self {
        case .strict: String(localized: "Nothing missed before today")
        case .gentle: String(localized: "Nothing undone before today")
        }
    }

    /// Missed › Earlier, when the filters match nothing (SPEC F-24).
    var filtersEmpty: String {
        switch self {
        case .strict: String(localized: "No missed tasks match these filters")
        case .gentle: String(localized: "No tasks match these filters")
        }
    }
}
