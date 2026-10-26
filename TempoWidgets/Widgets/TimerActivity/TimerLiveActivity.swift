import ActivityKit
import Core
import SwiftUI
import WidgetKit

/// The timer on the Lock Screen and in the Dynamic Island (SPEC F-31): the habit's name or "Timer", the clock, a
/// habit's progress toward its target, Pause or Resume, and Done. Tapping elsewhere opens the timer screen.
struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            TimerActivityView(attributes: context.attributes, state: context.state)
                .padding(16)
                .widgetURL(DeepLink.timer.url)
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    TimerActivityName(state: state)
                        .font(.headline)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerActivityClock(state: state)
                        .font(.headline.monospacedDigit())
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        TimerActivityProgress(state: state)
                        TimerActivityButtons(attributes: context.attributes, state: state)
                    }
                }
            } compactLeading: {
                Image(systemName: "timer").foregroundStyle(TimerActivityView.tint(state))
            } compactTrailing: {
                TimerActivityClock(state: state)
                    .monospacedDigit()
                    .frame(maxWidth: 56)
            } minimal: {
                Image(systemName: "timer").foregroundStyle(TimerActivityView.tint(state))
            }
            .widgetURL(DeepLink.timer.url)
        }
    }
}

#Preview("Lock Screen", as: .content, using: TimerActivityAttributes.previewHabit) {
    TimerLiveActivity()
} contentStates: {
    TimerActivityAttributes.ContentState.running
    TimerActivityAttributes.ContentState.paused
    TimerActivityAttributes.ContentState.generic
}

#Preview("Expanded", as: .dynamicIsland(.expanded), using: TimerActivityAttributes.previewHabit) {
    TimerLiveActivity()
} contentStates: {
    TimerActivityAttributes.ContentState.running
    TimerActivityAttributes.ContentState.paused
}

#Preview("Compact", as: .dynamicIsland(.compact), using: TimerActivityAttributes.previewHabit) {
    TimerLiveActivity()
} contentStates: {
    TimerActivityAttributes.ContentState.running
}

#Preview("Minimal", as: .dynamicIsland(.minimal), using: TimerActivityAttributes.previewHabit) {
    TimerLiveActivity()
} contentStates: {
    TimerActivityAttributes.ContentState.running
}
