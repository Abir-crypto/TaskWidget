import SwiftUI

/// The Today tab. A placeholder until T-12: the gear opens Settings and + opens the editor.
struct TodayView: View {
    let dependencies: AppDependencies
    @Bindable var router: NavigationRouter

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Today", systemImage: AppTab.today.systemImage, description: Text("This screen is being built.")
            )
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        router.isSettingsPresented = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .navigationDestination(isPresented: $router.isSettingsPresented) {
                SettingsView(dependencies: dependencies)
            }
            .floatingAddButton { router.openEditor(.new()) }
        }
        .safeAreaInset(edge: .bottom) { TimerBar() }
    }
}

#Preview {
    TodayView(dependencies: .preview(), router: NavigationRouter())
}
