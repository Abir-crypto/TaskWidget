import AppIntents
import Foundation

/// Resume in the Timer widget and the Now widget (SPEC F-18, F-21).
struct ResumeTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Resume Timer"
    static let isDiscoverable = false

    @MainActor
    func perform() async throws -> some IntentResult {
        try await run(in: IntentEnvironment.make())
        return .result()
    }

    @MainActor
    func run(in environment: IntentEnvironment) async throws {
        environment.timer.resume()
        await environment.refresh.refreshNowAndWait()
    }
}
