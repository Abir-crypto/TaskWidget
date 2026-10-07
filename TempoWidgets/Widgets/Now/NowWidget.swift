import SwiftUI
import WidgetKit

/// The Now widget (large): what's on now and next, with checkboxes and ▶; while a habit timer exists it
/// becomes that timer (SPEC F-21).
struct NowWidget: Widget {
    let kind = "NowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayTimelineProvider()) { entry in
            NowWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color("WidgetBackground") }
        }
        .configurationDisplayName("Now")
        .description("What's on now and next. Check off tasks and time habits.")
        .supportedFamilies([.systemLarge])
    }
}
