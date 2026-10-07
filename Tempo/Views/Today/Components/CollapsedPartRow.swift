import Core
import SwiftUI

/// An ended part of today folded into one line: "Morning · 2 done · 1 missed" (SPEC F-10).
struct CollapsedPartRow: View {
    let section: DaySection
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(summary)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(isExpanded ? Text("Hides the tasks") : Text("Shows the tasks"))
    }

    private var summary: String {
        var pieces = [section.part?.title ?? String(localized: "Anytime")]
        if section.doneCount > 0 { pieces.append(String(localized: "\(section.doneCount) done")) }
        if section.missedCount > 0 { pieces.append(String(localized: "\(section.missedCount) missed")) }
        return pieces.joined(separator: " · ")
    }
}

#Preview {
    List {
        CollapsedPartRow(
            section: DaySection(part: .morning, phase: .ended, window: 360..<720, items: []), isExpanded: false
        ) {}
    }
}
