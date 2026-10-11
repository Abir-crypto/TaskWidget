import Core
import SwiftUI

extension ThemePreset {
    /// The preset's system color, with its light and dark shades (ios.md §12).
    var color: Color {
        switch self {
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        case .red: .red
        case .orange: .orange
        case .green: .green
        case .teal: .teal
        }
    }

    /// The preset's name, for VoiceOver: "Blue", "Indigo", …
    var title: String {
        switch self {
        case .blue: String(localized: "Blue", comment: "Theme color")
        case .indigo: String(localized: "Indigo", comment: "Theme color")
        case .purple: String(localized: "Purple", comment: "Theme color")
        case .pink: String(localized: "Pink", comment: "Theme color")
        case .red: String(localized: "Red", comment: "Theme color")
        case .orange: String(localized: "Orange", comment: "Theme color")
        case .green: String(localized: "Green", comment: "Theme color")
        case .teal: String(localized: "Teal", comment: "Theme color")
        }
    }
}
