import SwiftUI
import WidgetKit

/// The Focus widget (medium): the one thing to do next, and what comes after. Information only (SPEC F-20).
struct FocusWidget: Widget {
    let kind = "FocusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayTimelineProvider()) { entry in
            FocusWidgetView(entry: entry)
                .widgetTheme(entry)
                .containerBackground(for: .widget) { Color("WidgetBackground") }
        }
        .configurationDisplayName("Focus")
        .description("The one thing to do next, and what comes after.")
        .supportedFamilies([.systemMedium])
    }
}
