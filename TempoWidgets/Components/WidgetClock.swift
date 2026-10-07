import Core
import SwiftUI
import WidgetKit

/// A timer clock that updates itself in a widget: counting up while running, frozen while paused (ios.md §9).
struct WidgetClock: View {
    let value: TimerClockValue

    var body: some View {
        switch value {
        case .running(let since):
            Text(since, style: .timer)
                .monospacedDigit()
        case .paused(let seconds):
            Text(TimerClockValue.text(seconds: seconds))
                .monospacedDigit()
        }
    }
}
