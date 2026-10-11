import SwiftUI
import WidgetKit

/// The Day widget (medium): a column of marks for each part of today, with no buttons (SPEC F-19).
struct DayWidget: Widget {
    let kind = "DayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayTimelineProvider()) { entry in
            DayWidgetView(entry: entry)
                .widgetTheme(entry)
                .containerBackground(for: .widget) { Color("WidgetBackground") }
        }
        .configurationDisplayName("Day")
        .description("Your day at a glance, part by part.")
        .supportedFamilies([.systemMedium])
    }
}
