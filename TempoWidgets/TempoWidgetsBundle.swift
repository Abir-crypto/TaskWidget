import SwiftUI
import WidgetKit

@main
struct TempoWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TimerWidget()  // .systemSmall
        NowWidget()  // .systemLarge
    }
}
