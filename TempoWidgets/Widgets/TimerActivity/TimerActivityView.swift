import ActivityKit
import Core
import SwiftUI
import WidgetKit

/// The Lock Screen's layout.
struct TimerActivityView: View {
    let attributes: TimerActivityAttributes
    let state: TimerActivityAttributes.ContentState

    /// The theme color (SPEC F-27).
    static func tint(_ state: TimerActivityAttributes.ContentState) -> Color {
        ThemeColor(storedValue: state.tint).color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                TimerActivityName(state: state).font(.headline)
                Spacer(minLength: 8)
                TimerActivityClock(state: state)
                    .font(.title2.weight(.semibold).monospacedDigit())
            }
            TimerActivityProgress(state: state)
            TimerActivityButtons(attributes: attributes, state: state)
        }
        .tint(Self.tint(state))
    }
}

#Preview {
    TimerActivityView(attributes: .previewHabit, state: .running)
        .padding()
}
