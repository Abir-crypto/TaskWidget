import SwiftUI
import WidgetKit

/// The Lock Screen widgets: the next task under the clock (rectangular) or above it (inline). Information only
/// (SPEC F-22).
struct LockScreenWidget: Widget {
    let kind = "LockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayTimelineProvider()) { entry in
            LockScreenWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Next task")
        .description("Your next task, on the Lock Screen.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
    }
}
