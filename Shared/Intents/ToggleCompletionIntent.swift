import AppIntents
import Core
import Foundation

/// The Now widget's checkboxes: marks a one-time task or progress habit done, or not done, without opening the
/// app (SPEC F-21, F-04).
struct ToggleCompletionIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Mark Task Done"
    static let isDiscoverable = false

    @Parameter(title: "Task")
    var taskID: String

    @Parameter(title: "Day")
    var day: Int

    @Parameter(title: "Done")
    var value: Bool

    init() {}

    init(taskID: UUID, day: DayKey) {
        self.taskID = taskID.uuidString
        self.day = day.rawValue
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        try await run(in: IntentEnvironment.make())
        return .result()
    }

    /// Completes or undoes, then refreshes every widget and the notifications.
    @MainActor
    func run(in environment: IntentEnvironment) async throws {
        guard let id = UUID(uuidString: taskID) else { return }
        let day = DayKey(rawValue: day)
        if value {
            try environment.tasks.complete(taskID: id, day: day)
        } else {
            try environment.tasks.undoCompletion(taskID: id, day: day)
        }
        await environment.refresh.refreshNowAndWait()
    }
}
