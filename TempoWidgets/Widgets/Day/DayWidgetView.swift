import Core
import SwiftUI
import WidgetKit

/// The Day widget's columns, marks and footer (SPEC F-19).
struct DayWidgetView: View {
    let entry: TodayEntry
    @Environment(\.showsWidgetContainerBackground) private var showsBackground

    var body: some View {
        if let snapshot = entry.snapshot {
            let content = DayWidgetContent(snapshot: snapshot, at: entry.date)
            if content.hasNoTasks {
                VStack(spacing: 6) {
                    Image(systemName: "sun.max").font(.title2).widgetAccentable().accessibilityHidden(true)
                    Text("No tasks today").font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .widgetURL(DeepLink.newTask(day: DayKey(entry.date, calendar: snapshot.calendar)).url)
            } else {
                VStack(spacing: 8) {
                    HStack(alignment: .top, spacing: 6) {
                        ForEach(content.columns, id: \.part) { column in
                            Link(destination: DeepLink.today(part: column.part).url) {
                                columnView(column)
                            }
                        }
                    }
                    footer(content)
                }
                .widgetURL(DeepLink.today().url)
            }
        } else {
            WidgetFailureView()
        }
    }

    private func columnView(_ column: DayColumn) -> some View {
        VStack(spacing: 6) {
            Text(column.part.title)
                .font(.caption.weight(column.isCurrent ? .bold : .medium))
                .foregroundStyle(column.isCurrent ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .widgetAccentable(column.isCurrent)
            VStack(spacing: 3) {
                ForEach(Array(column.marks.enumerated()), id: \.offset) { _, mark in
                    Image(systemName: mark.systemImage)
                        .font(.caption)
                        .foregroundStyle(color(for: mark))
                }
                if column.extraCount > 0 {
                    Text("+\(column.extraCount)").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            if column.hasTasks {
                Text(column.leftCount > 0 ? "\(column.leftCount) left" : "done")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 6)
        .background {
            // Without the widget's background (StandBy, some tinted styles) the fill is dropped; the part's bold
            // accent name still marks it (ios.md §9).
            if column.isCurrent && showsBackground {
                RoundedRectangle(cornerRadius: 10).fill(.tint.opacity(0.12))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(column.part.title)
        .accessibilityValue(accessibilityValue(for: column))
    }

    @ViewBuilder
    private func footer(_ content: DayWidgetContent) -> some View {
        if content.isAllDone {
            Text("You're free today").font(.caption.weight(.semibold)).foregroundStyle(.tint)
        } else if content.anytimeLeft > 0 {
            Text("Anytime · \(content.anytimeLeft) left").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
        }
    }

    private func color(for mark: DayMark) -> Color {
        switch mark {
        case .done: .green
        case .notDone: .secondary
        case .missed: .red
        case .partial: .orange
        }
    }

    private func accessibilityValue(for column: DayColumn) -> String {
        guard column.hasTasks else { return String(localized: "No tasks") }
        let done = column.marks.filter { $0 == .done }.count
        let missed = column.marks.filter { $0 == .missed }.count
        return String(localized: "\(done) done, \(missed) missed, \(column.leftCount) left")
    }
}

#Preview(as: .systemMedium) {
    DayWidget()
} timeline: {
    TodayEntry(date: .now, snapshot: .preview(timer: nil, data: .nowPreview))
    TodayEntry(date: .now, snapshot: .preview(timer: nil))
    TodayEntry.failed(.now)
}
