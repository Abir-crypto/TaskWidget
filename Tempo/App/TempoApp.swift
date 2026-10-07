import SwiftUI

@main
struct TempoApp: App {
    @State private var dependencies: Result<AppDependencies, any Error> = Result { try AppDependencies.live() }
    @State private var router = NavigationRouter()

    var body: some Scene {
        WindowGroup {
            switch dependencies {
            case .success(let dependencies):
                RootView(dependencies: dependencies, router: router)
                    .environment(dependencies)
                    .environment(router)
                    .task { dependencies.prepare() }
            case .failure:
                StoreErrorView()
            }
        }
    }
}
