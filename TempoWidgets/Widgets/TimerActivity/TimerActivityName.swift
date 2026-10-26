import ActivityKit
import Core
import SwiftUI
import WidgetKit

/// The habit's name, hidden while locked with Hide task names on (SPEC F-31, F-22), or "Timer".
struct TimerActivityName: View {
    let state: TimerActivityAttributes.ContentState

    var body: some View {
        if let title = state.habitTitle {
            Label {
                Text(title).privacySensitive(state.hidesName)
            } icon: {
                Image(systemName: "timer")
            }
            .lineLimit(1)
        } else {
            Label("Timer", systemImage: "timer")
        }
    }
}

#Preview {
    VStack {
        TimerActivityName(state: .running)
        TimerActivityName(state: .generic)
    }
}
