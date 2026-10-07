import SwiftUI

/// The task editor, presented as a sheet. A placeholder until T-11.
struct TaskEditorView: View {
    let dependencies: AppDependencies
    let request: EditorRequest
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "New task", systemImage: "square.and.pencil", description: Text("This screen is being built.")
            )
            .navigationTitle("New task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    TaskEditorView(dependencies: .preview(), request: .new())
}
