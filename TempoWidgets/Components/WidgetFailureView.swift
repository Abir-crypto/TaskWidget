import SwiftUI
import WidgetKit

/// Shown when a widget can't read its data; the timeline tries again 15 minutes later (SPEC F-17).
struct WidgetFailureView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "arrow.clockwise")
                .font(.title3)
                .widgetAccentable()
                .accessibilityHidden(true)
            Text("Open Tempo to refresh")
                .font(.footnote.weight(.medium))
                .multilineTextAlignment(.center)
        }
        .padding(8)
    }
}
