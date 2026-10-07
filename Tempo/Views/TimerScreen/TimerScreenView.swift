import SwiftUI

/// The timer screen. A placeholder until T-20.
struct TimerScreenView: View {
    let dependencies: AppDependencies
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ContentUnavailableView("Timer", systemImage: "timer", description: Text("This screen is being built."))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    TimerScreenView(dependencies: .preview())
}
