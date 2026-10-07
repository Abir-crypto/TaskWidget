import AppIntents
import Foundation

/// The Timer widget's Start: begins a generic timer without opening the app (SPEC F-18).
struct StartGenericTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Timer"
    static let isDiscoverable = false

    @MainActor
    func perform() async throws -> some IntentResult {
        try await run(in: IntentEnvironment.make())
        return .result()
    }

    @MainActor
    func run(in environment: IntentEnvironment) async throws {
        do {
            try environment.timer.startGenericTimer()
        } catch TimerError.timerExists {
            // A timer started elsewhere in the meantime; the widget just catches up.
        }
        await environment.refresh.refreshNowAndWait()
    }
}
