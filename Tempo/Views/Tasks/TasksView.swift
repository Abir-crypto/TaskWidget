import SwiftUI

/// The Tasks tab. A placeholder until T-13: the clock opens History and + opens the editor.
struct TasksView: View {
    let dependencies: AppDependencies
    @Bindable var router: NavigationRouter

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Tasks", systemImage: AppTab.tasks.systemImage, description: Text("This screen is being built.")
            )
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        router.isHistoryPresented = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .accessibilityLabel("History")
                }
            }
            .navigationDestination(isPresented: $router.isHistoryPresented) {
                HistoryView(dependencies: dependencies)
            }
            .floatingAddButton { router.openEditor(.new(type: .progress)) }
        }
        .safeAreaInset(edge: .bottom) { TimerBar() }
    }
}

#Preview {
    TasksView(dependencies: .preview(), router: NavigationRouter())
}
