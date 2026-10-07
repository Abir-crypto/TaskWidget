import SwiftUI

extension View {
    /// Puts what every screen expects in the environment, for previews: the dependencies, a router and the
    /// timer controller.
    @MainActor
    func previewEnvironment(_ dependencies: AppDependencies, router: NavigationRouter = NavigationRouter()) -> some View
    {
        environment(dependencies)
            .environment(router)
            .environment(TimerController(dependencies: dependencies, router: router))
    }
}
