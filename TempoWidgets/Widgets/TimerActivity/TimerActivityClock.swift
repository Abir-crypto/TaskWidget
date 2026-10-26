import ActivityKit
import Core
import SwiftUI
import WidgetKit

/// The clock counting up by itself, or the time so far and "Paused". A counting clock takes all the width it's
/// given, so its digits are pushed to the trailing edge.
struct TimerActivityClock: View {
    let state: TimerActivityAttributes.ContentState

    var body: some View {
        if state.runningSince == nil {
            HStack(spacing: 4) {
                Text(TimerClockValue.text(seconds: state.pausedSeconds))
                Image(systemName: "pause.fill").font(.caption).accessibilityLabel(Text("Paused"))
            }
        } else {
            WidgetClock(value: state.clock)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    VStack {
        TimerActivityClock(state: .running)
        TimerActivityClock(state: .paused)
    }
}
