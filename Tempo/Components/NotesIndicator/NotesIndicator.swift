import SwiftUI

/// The small icon on a row whose task has notes (SPEC F-10, F-11). The notes themselves show only in the editor and
/// Habit detail.
struct NotesIndicator: View {
    var body: some View {
        Image(systemName: "note.text")
            .font(.caption)
            .foregroundStyle(.secondary)
            .accessibilityLabel(Text("Has notes"))
    }
}

#Preview {
    HStack(spacing: 4) {
        Text(verbatim: "Renew passport")
        NotesIndicator()
    }
}
