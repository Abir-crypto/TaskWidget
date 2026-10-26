import AppIntents
import Foundation

/// Discard in the Now widget's timer mode: stops the timer and saves nothing (SPEC F-21, F-06).
struct DiscardTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Discard Timer"
    static let isDiscoverable = false

    @MainActor
    func perform() async throws -> some IntentResult {
        try await run(in: IntentEnvironment.make())
        return .result()
    }

    @MainActor
    func run(in environment: IntentEnvironment) async throws {
        environment.timer.discard()
        await environment.refresh.refreshNowAndWait()
    }
}
