import Core
import SwiftUI
import WidgetKit

/// The Now widget's timer mode (SPEC F-21): the habit, the clock, progress toward today's target, and
/// Pause/Resume, Done and Discard.
struct NowTimerView: View {
    let timer: NowTimer

    var body: some View {
        VStack(spacing: 14) {
            Label("Timer", systemImage: "timer")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(timer.title)
                .font(.title2.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
            WidgetClock(value: timer.clock)
                .font(.system(size: 52, weight: .light, design: .rounded))
                .widgetAccentable()
            if !timer.clock.isRunning {
                Label("Paused", systemImage: "pause.circle").font(.headline)
            }
            if let target = timer.targetMinutes {
                VStack(spacing: 4) {
                    if let interval = timer.progressInterval {
                        ProgressView(timerInterval: interval, countsDown: false) {
                            EmptyView()
                        } currentValueLabel: {
                            EmptyView()
                        }
                    } else {
                        ProgressView(value: Double(min(timer.minutesToday, target)), total: Double(max(target, 1)))
                    }
                    Text("\(timer.minutesToday) of \(target) min today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tint(.accentColor)
                .widgetAccentable()
            }
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                if timer.clock.isRunning {
                    Button(intent: PauseTimerIntent()) {
                        Label("Pause", systemImage: "pause.fill").frame(maxWidth: .infinity)
                    }
                } else {
                    Button(intent: ResumeTimerIntent()) {
                        Label("Resume", systemImage: "play.fill").frame(maxWidth: .infinity)
                    }
                }
                Button(intent: FinishHabitTimerIntent()) {
                    Label("Done", systemImage: "checkmark").frame(maxWidth: .infinity)
                }
                .modifier(ProminentWidgetButton())
            }
            .font(.subheadline.weight(.semibold))
            Button(role: .destructive, intent: DiscardTimerIntent()) {
                Text("Discard")
            }
            .font(.caption)
            .buttonStyle(.plain)
            .foregroundStyle(.red)
        }
    }
}
