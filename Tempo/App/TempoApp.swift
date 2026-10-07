import SwiftUI

@main
struct TempoApp: App {
    @State private var dependencies: Result<AppDependencies, any Error> = Result { try AppDependencies.live() }

    var body: some Scene {
        WindowGroup {
            switch dependencies {
            case .success(let dependencies):
                RootView()
                    .task { dependencies.prepare() }
            case .failure:
                StoreErrorView()
            }
        }
    }
}
