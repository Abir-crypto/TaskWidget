import Core
import UIKit

extension Appearance {
    /// The windows' interface style: System leaves it to the device (ios.md §12).
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: .unspecified
        case .dark: .dark
        case .light: .light
        }
    }

    /// The choice's name in Settings › Theme: "System", "Dark" or "Light".
    var title: String {
        switch self {
        case .system: String(localized: "System", comment: "Appearance: follow the device's light or dark mode")
        case .dark: String(localized: "Dark", comment: "Appearance")
        case .light: String(localized: "Light", comment: "Appearance")
        }
    }
}
