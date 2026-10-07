import SwiftUI
import WidgetKit

/// T-01 placeholder so the extension appears in the widget gallery. Remove it when the first real widget lands (T-23).
struct PlaceholderWidget: Widget {
    let kind = "PlaceholderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlaceholderProvider()) { _ in
            VStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.title)
                    .widgetAccentable()
                    .accessibilityHidden(true)
                Text("Tempo")
                    .font(.headline)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Tempo")
        .description("A placeholder until the real widgets are built.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    PlaceholderWidget()
} timeline: {
    PlaceholderEntry(date: .now)
}
