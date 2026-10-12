import Core
import SwiftUI

/// A final status shown as text and an icon, never by color alone (SPEC F-17, ios.md §14).
struct StatusLabel: View {
    let status: Status
    @Environment(\.missedStyle) private var missedStyle

    var body: some View {
        switch status {
        case .missed:
            // "Missed" in red, or "Not done" in grey (SPEC F-30).
            Label(missedStyle.statusTitle, systemImage: missedStyle.systemImage).foregroundStyle(missedStyle.color)
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
        StatusLabel(status: .missed).environment(\.missedStyle, .strict)
        StatusLabel(status: .short)
        StatusLabel(status: .done)
    }
    .font(.footnote)
}
