import SwiftUI

@main
struct TempoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var dependencies: Result<AppDependencies, any Error> = Result { try AppDependencies.live() }
    @State private var router = NavigationRouter()

    var body: some Scene {
        WindowGroup {
            switch dependencies {
            case .success(let dependencies):
                RootView(dependencies: dependencies, router: router)
                    .environment(dependencies)
                    .environment(router)
                    .task {
                        dependencies.prepare()
                        appDelegate.onResponse = { response in
                            NotificationActionHandler.handle(response, dependencies: dependencies, router: router)
                        }
                        await dependencies.reminders.rebuild()
                        BackgroundRefresh.schedule(after: dependencies.clock.now)
                    }
            case .failure:
                StoreErrorView()
            }
        }
        .backgroundTask(.appRefresh(BackgroundRefresh.identifier)) {
            await refreshInBackground()
        }
    }

    /// Rebuilds the notification plan and asks for the next background refresh.
    @MainActor
    private func refreshInBackground() async {
        guard case .success(let dependencies) = dependencies else { return }
        await dependencies.reminders.rebuild()
        BackgroundRefresh.schedule(after: dependencies.clock.now)
    }
}
