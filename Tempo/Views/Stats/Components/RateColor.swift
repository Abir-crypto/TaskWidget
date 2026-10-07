import Core
import SwiftUI

/// The color for a day's or month's completion in the Stats charts. Each use also shows the number or a label,
/// so the color never stands alone.
enum RateColor {
    static func color(for rate: CompletionRate) -> Color {
        guard let percent = rate.percent else { return .clear }
        switch percent {
        case 100: return .green
        case 50...: return .green.opacity(0.55)
        case 1...: return .orange
        default: return .red
        }
    }
}
