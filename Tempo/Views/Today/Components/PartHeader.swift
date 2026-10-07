import Core
import SwiftUI

/// A section's header on Today: the part's name, highlighted with "ends in …" while it's in progress.
struct PartHeader: View {
    let section: DaySection
    /// Minutes until the part in progress ends.
    let minutesLeft: Int?

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(section.phase == .current ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                .fontWeight(section.phase == .current ? .bold : .regular)
            Spacer()
            if let minutesLeft {
                Text("ends in \(DurationFormatter.short(minutes: minutesLeft))")
                    .foregroundStyle(.tint)
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var title: String {
        section.part?.title ?? String(localized: "Anytime")
    }
}

#Preview {
    List {
        Section {
            Text(verbatim: "Row")
        } header: {
            PartHeader(
                section: DaySection(part: .noon, phase: .current, window: 720..<1020, items: []), minutesLeft: 80)
        }
    }
}
