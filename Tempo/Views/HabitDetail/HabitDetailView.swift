import SwiftUI

/// Habit detail. A placeholder until T-15.
struct HabitDetailView: View {
    let dependencies: AppDependencies
    let taskID: UUID

    var body: some View {
        ContentUnavailableView(
            "Habit", systemImage: "chart.line.uptrend.xyaxis", description: Text("This screen is being built.")
        )
        .navigationTitle("Habit")
    }
}

#Preview {
    NavigationStack { HabitDetailView(dependencies: .preview(), taskID: UUID()) }
}
