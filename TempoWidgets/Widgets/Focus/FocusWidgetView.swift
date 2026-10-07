import Core
import SwiftUI
import WidgetKit

/// The Focus widget's "when" line, title, progress and "Then:" line, or "You're free today" (SPEC F-20).
struct FocusWidgetView: View {
    let entry: TodayEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            let content = FocusWidgetContent(snapshot: snapshot, at: entry.date)
            Group {
                switch content {
                case .next(let item, let then):
                    next(item, then: then)
                case .free(let allDoneCount):
                    free(allDoneCount)
                }
            }
            .widgetURL(content.url)
        } else {
            WidgetFailureView()
        }
    }

    private func next(_ item: FocusItem, then: FocusItem?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            whenLine(item.when)
                .font(.caption.weight(.bold))
                .foregroundStyle(.tint)
                .widgetAccentable()
                .lineLimit(1)
            Text(item.title)
                .font(.title2.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            if let progress = item.progress {
                Label(progress, systemImage: "timer")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if let then {
                (Text("Then: ").fontWeight(.semibold) + Text(then.title))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// "NEXT · 12:30 · in 45 min" counts down by itself; the other lines are fixed text.
    @ViewBuilder
    private func whenLine(_ when: FocusWhen) -> some View {
        if case .next(_, let date) = when, date > entry.date {
            Text(when.label) + Text(" · ") + Text("in ") + Text(date, style: .relative)
        } else {
            Text(when.label)
        }
    }

    private func free(_ allDoneCount: Int?) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.seal")
                .font(.title)
                .foregroundStyle(.tint)
                .widgetAccentable()
                .accessibilityHidden(true)
            Text("You're free today").font(.headline)
            if let allDoneCount {
                Text("All ^[\(allDoneCount) task](inflect: true) done")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview(as: .systemMedium) {
    FocusWidget()
} timeline: {
    TodayEntry(date: .now, snapshot: .preview(timer: nil, data: .nowPreview))
    TodayEntry(date: .now, snapshot: .preview(timer: nil))
    TodayEntry.failed(.now)
}
