import SwiftUI
import WidgetKit

/// The Timer widget (small): Start a generic timer, then Pause/Resume and Done; a habit timer started elsewhere
/// is shown without controls (SPEC F-18).
struct TimerWidget: Widget {
    let kind = "TimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayTimelineProvider()) { entry in
            TimerWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color("WidgetBackground") }
        }
        .configurationDisplayName("Timer")
        .description("Start a timer and choose the habit when you're done.")
        .supportedFamilies([.systemSmall])
    }
}
