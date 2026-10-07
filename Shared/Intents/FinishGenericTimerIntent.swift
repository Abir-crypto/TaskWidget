import AppIntents
import Core
import Foundation

/// The Timer widget's Done: freezes the time at the tap and opens the app's task picker (SPEC F-18, F-06).
/// `openAppWhenRun` can't change at runtime, which is why the Now widget has its own finish intent (ios.md §8).
struct FinishGenericTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "Finish Timer"
    static let isDiscoverable = false
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        try await run(in: IntentEnvironment.make())
        return .result()
    }

    @MainActor
    func run(in environment: IntentEnvironment) async throws {
        guard environment.timer.state?.kind == .generic else { return }
        let finished = try environment.timer.finish()
        environment.deviceState.pendingOpenAction = .chooseTaskForTimer(finished)
        // If this runs inside the app, tell it straight away; otherwise it reads the action when it opens.
        NotificationCenter.default.post(name: .pendingOpenActionWritten, object: nil)
        await environment.refresh.refreshNowAndWait()
    }
}

extension Notification.Name {
    /// Posted when a widget button leaves a pending open action for the app.
    static let pendingOpenActionWritten = Notification.Name("com.applab.tempo.pendingOpenActionWritten")
}
