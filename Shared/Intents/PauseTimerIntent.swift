import AppIntents
import Foundation

/// Pause in the Timer widget and the Now widget (SPEC F-18, F-21).
struct PauseTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "Pause Timer"
    static let isDiscoverable = false

    @MainActor
    func perform() async throws -> some IntentResult {
        try await run(in: IntentEnvironment.make())
        return .result()
    }

    @MainActor
    func run(in environment: IntentEnvironment) async throws {
        environment.timer.pause()
        await environment.refresh.refreshNowAndWait()
    }
}
