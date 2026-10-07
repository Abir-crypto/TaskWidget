import SwiftUI

/// Shown instead of the app when the data store can't be opened (ios.md §6).
struct StoreErrorView: View {
    var body: some View {
        ContentUnavailableView(
            "Can't open your tasks",
            systemImage: "exclamationmark.triangle",
            description: Text("Something went wrong while opening Tempo's data. Close the app and open it again.")
        )
    }
}

#Preview {
    StoreErrorView()
}
