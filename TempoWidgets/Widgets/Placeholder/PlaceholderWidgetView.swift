import Core
import SwiftUI
import WidgetKit

/// Today's tasks left, or the failure message (T-22, until T-23).
struct PlaceholderWidgetView: View {
    let entry: TodayEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            let plan = snapshot.plan(at: entry.date)
            let left = plan.items.filter { $0.status.isPending }.count
            VStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.title)
                    .widgetAccentable()
                    .accessibilityHidden(true)
                Text("Tempo")
                    .font(.headline)
                Text("\(left) left today")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } else {
            WidgetFailureView()
        }
    }
}
