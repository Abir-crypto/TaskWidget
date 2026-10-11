import Core
import SwiftUI

extension ThemeColor {
    /// The color to tint with (SPEC F-27): a preset's system color, which has a light and a dark shade, or the
    /// custom color as it is.
    var color: Color {
        switch self {
        case .preset(let preset):
            preset.color
        case .custom(let red, let green, let blue):
            Color(.sRGB, red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
        }
    }
}
