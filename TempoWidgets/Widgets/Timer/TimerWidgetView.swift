import Core
import SwiftUI
import WidgetKit

/// The Timer widget's states (SPEC F-18).
struct TimerWidgetView: View {
    let entry: TodayEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            let state = TimerWidgetState(timer: snapshot.timer, habitTitle: snapshot.timerHabitTitle)
            content(state)
                .widgetURL(state.url)
        } else {
            WidgetFailureView()
        }
    }

    @ViewBuilder
    private func content(_ state: TimerWidgetState) -> some View {
        switch state {
        case .idle:
            VStack(spacing: 10) {
                Label("Timer", systemImage: "timer")
                    .font(.headline)
                    .widgetAccentable()
                Spacer(minLength: 0)
                Button(intent: StartGenericTimerIntent()) {
                    Label("Start", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .widgetAccentable()
            }
        case .generic(let clock):
            VStack(alignment: .leading, spacing: 6) {
                Label("Timer", systemImage: "timer")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                WidgetClock(value: clock)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .widgetAccentable()
                Text(clock.isRunning ? "Running" : "Paused")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    if clock.isRunning {
                        Button(intent: PauseTimerIntent()) {
                            Image(systemName: "pause.fill").frame(maxWidth: .infinity)
                        }
                        .accessibilityLabel(Text("Pause"))
                    } else {
                        Button(intent: ResumeTimerIntent()) {
                            Image(systemName: "play.fill").frame(maxWidth: .infinity)
                        }
                        .accessibilityLabel(Text("Resume"))
                    }
                    Button(intent: FinishGenericTimerIntent()) {
                        Text("Done").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .widgetAccentable()
                }
                .font(.footnote.weight(.semibold))
            }
        case .habit(let title, let clock):
            VStack(alignment: .leading, spacing: 6) {
                Label("Timer", systemImage: "timer")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.headline)
                    .lineLimit(2)
                Spacer(minLength: 0)
                if clock.isRunning {
                    WidgetClock(value: clock)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .widgetAccentable()
                } else {
                    Label("Paused", systemImage: "pause.circle")
                        .font(.headline)
                        .widgetAccentable()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview("Idle", as: .systemSmall) {
    TimerWidget()
} timeline: {
    TodayEntry(date: .now, snapshot: .preview(timer: nil))
}

#Preview("Generic", as: .systemSmall) {
    TimerWidget()
} timeline: {
    TodayEntry(date: .now, snapshot: .preview(timer: .previewGeneric(running: true)))
    TodayEntry(date: .now, snapshot: .preview(timer: .previewGeneric(running: false)))
}

#Preview("Habit", as: .systemSmall) {
    TimerWidget()
} timeline: {
    TodayEntry(date: .now, snapshot: .preview(timer: .previewHabit(running: true), habitTitle: "Read"))
    TodayEntry(date: .now, snapshot: .preview(timer: .previewHabit(running: false), habitTitle: "Read"))
}

#Preview("Failed", as: .systemSmall) {
    TimerWidget()
} timeline: {
    TodayEntry.failed(.now)
}
