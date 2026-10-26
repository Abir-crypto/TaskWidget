import ActivityKit
import Core
import SwiftUI
import WidgetKit

/// Pause or Resume, and Done: a habit timer's Done saves without opening the app, a generic timer's Done opens the
/// task picker (SPEC F-06). No Discard (SPEC F-31).
struct TimerActivityButtons: View {
    let attributes: TimerActivityAttributes
    let state: TimerActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 8) {
            if state.runningSince != nil {
                Button(intent: PauseTimerIntent()) {
                    Label("Pause", systemImage: "pause.fill").frame(maxWidth: .infinity)
                }
            } else {
                Button(intent: ResumeTimerIntent()) {
                    Label("Resume", systemImage: "play.fill").frame(maxWidth: .infinity)
                }
            }
            if attributes.kind == .habit {
                Button(intent: FinishHabitTimerIntent()) {
                    Text("Done").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(intent: FinishGenericTimerIntent()) {
                    Text("Done").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .font(.subheadline.weight(.semibold))
        .tint(TimerActivityView.tint(state))
    }
}

#Preview {
    TimerActivityButtons(attributes: .previewHabit, state: .running)
        .padding()
}
