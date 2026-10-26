import SwiftUI
import WidgetKit

@main
struct TempoWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TimerWidget()  // .systemSmall
        DayWidget()  // .systemMedium
        FocusWidget()  // .systemMedium
        NowWidget()  // .systemLarge
        LockScreenWidget()  // .accessoryRectangular, .accessoryInline
        TimerLiveActivity()  // the timer on the Lock Screen and in the Dynamic Island
    }
}
