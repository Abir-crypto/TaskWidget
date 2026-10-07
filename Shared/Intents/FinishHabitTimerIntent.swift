import AppIntents
import Foundation

/// Done in the Now widget's timer mode: freezes the time and saves it without opening the app; the widget goes
/// back to its list (SPEC F-21, F-06). Under a minute, nothing is saved.
struct FinishHabitTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "Finish Habit Timer"
    static let isDiscoverable = false

    @MainActor
    func perform() async throws -> some IntentResult {
        try await run(in: IntentEnvironment.make())
        return .result()
    }

    @MainActor
    func run(in environment: IntentEnvironment) async throws {
        guard environment.timer.state?.kind == .habit else { return }
        _ = try environment.timer.finishHabitTimer()
        await environment.refresh.refreshNowAndWait()
    }
}
