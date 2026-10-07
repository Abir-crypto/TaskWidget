import Core
import SwiftUI
import WidgetKit

/// Until the Timer widget replaces it (T-23), a small widget that shows the foundation working: today's tasks
/// left, read from the shared store and updated at every part boundary (T-22).
struct PlaceholderWidget: Widget {
    let kind = "PlaceholderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayTimelineProvider()) { entry in
            PlaceholderWidgetView(entry: entry)
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
    TodayEntry(date: .now, snapshot: .empty(calendar: .autoupdatingCurrent))
    TodayEntry.failed(.now)
}
