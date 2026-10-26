import AppIntents
import Foundation

/// ▶ in the Now widget: starts a habit timer without opening the app, and the widget turns into the timer
/// (SPEC F-21, F-06).
struct StartHabitTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Start Habit Timer"
    static let isDiscoverable = false

    @Parameter(title: "Habit")
    var taskID: String

    init() {}

    init(taskID: UUID) {
        self.taskID = taskID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        try await run(in: IntentEnvironment.make())
        return .result()
    }

    @MainActor
    func run(in environment: IntentEnvironment) async throws {
        guard let id = UUID(uuidString: taskID) else { return }
        do {
            try environment.timer.startHabitTimer(taskID: id)
        } catch TimerError.timerExists {
            // Another timer started meanwhile; the widget just catches up.
        }
        await environment.refresh.refreshNowAndWait()
    }
}
