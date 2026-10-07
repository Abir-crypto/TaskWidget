import SwiftUI

/// History, opened from the clock on Tasks. A placeholder until T-14.
struct HistoryView: View {
    let dependencies: AppDependencies

    var body: some View {
        ContentUnavailableView(
            "History", systemImage: "clock.arrow.circlepath", description: Text("This screen is being built.")
        )
        .navigationTitle("History")
    }
}

#Preview {
    NavigationStack { HistoryView(dependencies: .preview()) }
}
