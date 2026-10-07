import SwiftUI

/// The Stats tab. A placeholder until T-18.
struct StatsView: View {
    let dependencies: AppDependencies
    @Bindable var router: NavigationRouter

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Stats", systemImage: AppTab.stats.systemImage, description: Text("This screen is being built.")
            )
            .navigationTitle("Stats")
        }
        .safeAreaInset(edge: .bottom) { TimerBar() }
    }
}

#Preview {
    StatsView(dependencies: .preview(), router: NavigationRouter())
}
