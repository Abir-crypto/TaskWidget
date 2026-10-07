import Core
import SwiftUI

/// The task picker for a finished generic timer. A placeholder until T-20.
struct TaskPickerView: View {
    let dependencies: AppDependencies
    let request: TaskPickerRequest
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Choose a task", systemImage: "list.bullet", description: Text("This screen is being built.")
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    TaskPickerView(
        dependencies: .preview(),
        request: TaskPickerRequest(
            timer: FinishedTimer(habitID: nil, day: DayKey(year: 2026, month: 10, day: 6), seconds: 600)))
}
