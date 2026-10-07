import Core
import SwiftUI

/// A final status shown as text and an icon, never by color alone (SPEC F-17, ios.md §14).
struct StatusLabel: View {
    let status: Status

    var body: some View {
        switch status {
        case .missed:
            Label("Missed", systemImage: "xmark.circle").foregroundStyle(.red)
        case .short:
            Label("Short", systemImage: "circle.lefthalf.filled").foregroundStyle(.orange)
        case .done:
            Label("Done", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
        case .upcoming, .open:
            EmptyView()
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        StatusLabel(status: .missed)
        StatusLabel(status: .short)
        StatusLabel(status: .done)
    }
    .font(.footnote)
}
