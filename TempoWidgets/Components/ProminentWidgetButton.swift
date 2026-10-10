import SwiftUI
import WidgetKit

/// A widget's main button: filled in full color, bordered in the tinted and clear styles, where a filled
/// button's fill and label take the same color and the label disappears (SPEC F-17, T-31).
struct ProminentWidgetButton: ViewModifier {
    @Environment(\.widgetRenderingMode) private var renderingMode

    func body(content: Content) -> some View {
        if renderingMode == .fullColor {
            content.buttonStyle(.borderedProminent)
        } else {
            content.buttonStyle(.bordered).widgetAccentable()
        }
    }
}
