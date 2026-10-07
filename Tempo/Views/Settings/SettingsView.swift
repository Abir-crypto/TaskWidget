import SwiftUI

/// Settings, opened from the gear on Today. A placeholder until T-10.
struct SettingsView: View {
    let dependencies: AppDependencies

    var body: some View {
        ContentUnavailableView(
            "Settings", systemImage: "gearshape", description: Text("This screen is being built.")
        )
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack { SettingsView(dependencies: .preview()) }
}
