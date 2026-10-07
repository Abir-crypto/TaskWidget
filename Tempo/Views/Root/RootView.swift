import SwiftUI

/// Placeholder screen from T-01. T-09 replaces it with the tab layout.
struct RootView: View {
    var body: some View {
        ContentUnavailableView(
            "Tempo",
            systemImage: "clock",
            description: Text("The app is being built.")
        )
    }
}

#Preview {
    RootView()
}
