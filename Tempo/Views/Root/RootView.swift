import SwiftUI

/// The four tabs, what's presented over them, and where links lead (SPEC F-09).
struct RootView: View {
    let dependencies: AppDependencies
    @Bindable var router: NavigationRouter
    @State private var model: RootViewModel
    @Environment(\.scenePhase) private var scenePhase

    init(dependencies: AppDependencies, router: NavigationRouter) {
        self.dependencies = dependencies
        self.router = router
        _model = State(initialValue: RootViewModel(missed: dependencies.missed))
    }

    var body: some View {
        TabView(selection: $router.selectedTab) {
            TodayView(dependencies: dependencies, router: router)
                .tabItem { Label(AppTab.today.title, systemImage: AppTab.today.systemImage) }
                .tag(AppTab.today)
            TasksView(dependencies: dependencies, router: router)
                .tabItem { Label(AppTab.tasks.title, systemImage: AppTab.tasks.systemImage) }
                .tag(AppTab.tasks)
            MissedView(dependencies: dependencies, router: router)
                .tabItem { Label(AppTab.missed.title, systemImage: AppTab.missed.systemImage) }
                .tag(AppTab.missed)
                .badge(model.missedCount)
            StatsView(dependencies: dependencies, router: router)
                .tabItem { Label(AppTab.stats.title, systemImage: AppTab.stats.systemImage) }
                .tag(AppTab.stats)
        }
        .background {
            // The badge changes at part boundaries, so it's recounted every minute (ios.md §4, rule 4).
            TimelineView(.everyMinute) { context in
                Color.clear.task(id: context.date) { model.load() }
            }
        }
        .task(id: dependencies.refresh.revision) { model.load() }
        .sheet(item: $router.editor) { request in
            TaskEditorView(dependencies: dependencies, request: request)
        }
        .sheet(isPresented: $router.isTimerScreenPresented) {
            TimerScreenView(dependencies: dependencies)
        }
        .sheet(item: $router.taskPicker) { request in
            TaskPickerView(dependencies: dependencies, request: request)
        }
        .onOpenURL { url in
            router.open(DeepLink(url: url))
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            switch phase {
            case .active:
                if let action = dependencies.deviceState.pendingOpenAction {
                    dependencies.deviceState.pendingOpenAction = nil
                    router.handle(action)
                }
                // A widget may have changed data while the app was in the background.
                dependencies.refresh.dataMayHaveChanged()
            case .background:
                router.didEnterBackground()
            default:
                break
            }
        }
    }
}

#Preview {
    RootView(dependencies: .preview(), router: NavigationRouter())
}
