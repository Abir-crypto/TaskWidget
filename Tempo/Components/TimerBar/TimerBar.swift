import SwiftUI

/// The bar above the tab bar on every screen while a timer exists: the habit (or "Timer"), the clock,
/// Pause/Resume and Done; tapping it opens the timer screen (SPEC F-06). After Done it shows the confirmation
/// instead. Placed with `.safeAreaInset(edge: .bottom)` on every tab's root.
struct TimerBar: View {
    @Environment(TimerController.self) private var controller
    @Environment(NavigationRouter.self) private var router

    var body: some View {
        if let toast = controller.toast {
            ConfirmationToast(
                toast: toast, onUndo: { controller.undo(toast) }, onChangeTask: { controller.changeTask(toast) })
        } else if let timer = controller.active {
            bar(timer)
        }
    }

    private func bar(_ timer: ActiveTimer) -> some View {
        HStack(spacing: 12) {
            Button {
                router.isTimerScreenPresented = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: timer.isRunning ? "timer" : "pause.circle")
                        .font(.title3)
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(timer.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            TimerClock(timer: timer, now: controller.now)
                            if !timer.isRunning { Text("· Paused") }
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("Opens the timer"))

            Button {
                timer.isRunning ? controller.pause() : controller.resume()
            } label: {
                Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .accessibilityLabel(timer.isRunning ? Text("Pause") : Text("Resume"))

            Button("Done") { controller.done() }
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    let router = NavigationRouter()
    return List(1...5, id: \.self) { Text(verbatim: "Row \($0)") }
        .safeAreaInset(edge: .bottom) { TimerBar() }
        .environment(TimerController(dependencies: dependencies, router: router))
        .environment(router)
}
