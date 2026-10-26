import ActivityKit
import Core
import SwiftUI
import WidgetKit

/// A habit timer's progress toward the day's target, including time logged earlier: "22:15 of 30 min today".
struct TimerActivityProgress: View {
    let state: TimerActivityAttributes.ContentState

    var body: some View {
        if let target = state.targetMinutes, target > 0 {
            let targetSeconds = TimeInterval(target * 60)
            VStack(alignment: .leading, spacing: 4) {
                if let since = state.runningSince {
                    // Counting from the moment today's total was zero, so the bar and the text move by themselves.
                    let start = since.addingTimeInterval(-TimeInterval(state.earlierSeconds))
                    ProgressView(timerInterval: start...start.addingTimeInterval(targetSeconds), countsDown: false) {
                        EmptyView()
                    } currentValueLabel: {
                        EmptyView()
                    }
                    // One text, so the counting part doesn't stretch across the row.
                    Text("\(Text(timerInterval: start...Date.distantFuture, countsDown: false)) of \(target) min today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    let total = TimeInterval(state.earlierSeconds + state.pausedSeconds)
                    ProgressView(value: min(total / targetSeconds, 1))
                    Text("\(DurationFormatter.progress(minutes: Int(total) / 60, target: target)) today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    VStack {
        TimerActivityProgress(state: .running)
        TimerActivityProgress(state: .paused)
    }
    .padding()
}
