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
                .modifier(ProminentWidgetButton())
            }
        case .generic(let clock):
            running(title: String(localized: "Timer"), clock: clock, isHabit: false)
        case .habit(let title, let clock):
            running(title: title, clock: clock, isHabit: true)
        }
    }

    /// A timer with its controls: Pause or Resume, and Done. Done on a generic timer opens the task picker; on a habit
    /// timer it saves without opening the app (SPEC F-06, F-18, D-111).
    private func running(title: String, clock: TimerClockValue, isHabit: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: "timer")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
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
                if isHabit {
                    Button(intent: FinishHabitTimerIntent()) {
                        Text("Done").frame(maxWidth: .infinity)
                    }
                    .modifier(ProminentWidgetButton())
                } else {
                    Button(intent: FinishGenericTimerIntent()) {
                        Text("Done").frame(maxWidth: .infinity)
                    }
                    .modifier(ProminentWidgetButton())
                }
            }
            .font(.footnote.weight(.semibold))
        }
    }
}

#Preview("Idle", as: .systemSmall) {
    TimerWidget()
} timeline: {
    TodayEntry(date: .now, snapshot: .preview(timer: nil))
    TodayEntry(date: .now, snapshot: .preview(timer: nil, theme: .preset(.green)))
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
