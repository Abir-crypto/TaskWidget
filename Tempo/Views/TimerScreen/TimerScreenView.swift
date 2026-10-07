import Core
import SwiftUI

/// The timer screen (SPEC F-06): a large clock, the habit, Pause/Resume, Done and Discard. For habit timers it
/// shows progress toward today's target, including time logged earlier that day.
struct TimerScreenView: View {
    let dependencies: AppDependencies
    @Environment(TimerController.self) private var controller
    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmingDiscard = false

    var body: some View {
        NavigationStack {
            Group {
                if let timer = controller.active {
                    content(timer)
                } else {
                    ContentUnavailableView("No timer running", systemImage: "timer")
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .confirmationDialog("Discard this timer?", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
                Button("Discard", role: .destructive) { controller.discard() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Its time won't be saved.")
            }
        }
    }

    private func content(_ timer: ActiveTimer) -> some View {
        VStack(spacing: 28) {
            Spacer()
            Text(timer.title)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
            TimerClock(timer: timer, now: controller.now)
                .font(.system(size: 64, weight: .light, design: .rounded))
                .accessibilityLabel(Text("Time"))
            if !timer.isRunning {
                Text("Paused").font(.headline).foregroundStyle(.secondary)
            }
            if let target = timer.targetMinutes {
                progress(timer, target: target)
            }
            Spacer()
            HStack(spacing: 16) {
                Button {
                    timer.isRunning ? controller.pause() : controller.resume()
                } label: {
                    Label(
                        timer.isRunning ? "Pause" : "Resume", systemImage: timer.isRunning ? "pause.fill" : "play.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("timer-screen-pause")
                Button {
                    controller.done()
                } label: {
                    Label("Done", systemImage: "checkmark").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("timer-screen-done")
            }
            .controlSize(.large)
            Button("Discard", role: .destructive) { isConfirmingDiscard = true }
        }
        .padding()
    }

    /// "22 of 30 min today", with a bar that fills as the timer runs.
    private func progress(_ timer: ActiveTimer, target: Int) -> some View {
        // Recalculated every 15 seconds, so a completed minute shows up promptly.
        TimelineView(.periodic(from: .now, by: 15)) { _ in
            let minutes = timer.minutesBefore + Int(TimerRules.elapsed(timer.state, now: controller.now) / 60)
            VStack(spacing: 8) {
                ProgressView(value: Double(min(minutes, target)), total: Double(max(target, 1)))
                Text("\(minutes) of \(target) min today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    return TimerScreenView(dependencies: dependencies)
        .environment(TimerController(dependencies: dependencies, router: NavigationRouter()))
}
