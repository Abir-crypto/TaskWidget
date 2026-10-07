import SwiftUI

/// The Missed tab. A placeholder until T-16.
struct MissedView: View {
    let dependencies: AppDependencies
    @Bindable var router: NavigationRouter

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Missed", systemImage: AppTab.missed.systemImage, description: Text("This screen is being built.")
            )
            .navigationTitle("Missed")
        }
        .safeAreaInset(edge: .bottom) { TimerBar() }
    }
}

#Preview {
    MissedView(dependencies: .preview(), router: NavigationRouter())
}
