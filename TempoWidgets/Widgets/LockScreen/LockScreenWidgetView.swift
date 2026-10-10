import SwiftUI
import WidgetKit

/// The next task's two lines (rectangular) or one line (inline), or "You're free today" (SPEC F-22). Titles are
/// privacy-sensitive when "Hide task names on the Lock Screen" is on, so they're hidden while the device is locked.
struct LockScreenWidgetView: View {
    let entry: TodayEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let snapshot = entry.snapshot {
            let content = LockScreenWidgetContent(snapshot: snapshot, at: entry.date)
            Group {
                if family == .accessoryInline {
                    inline(content)
                } else {
                    rectangular(content)
                }
            }
            .widgetURL(content.url)
        } else if family == .accessoryInline {
            Label("Open Tempo to refresh", systemImage: "arrow.clockwise")
        } else {
            WidgetFailureView()
        }
    }

    private func rectangular(_ content: LockScreenWidgetContent) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            switch content {
            case .next(let item):
                // "Evening · until 9:00 PM" is wider than the widget at the headline size, so it shrinks to fit.
                topLine(item)
                    .font(.headline)
                    .widgetAccentable()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(item.title)
                    .lineLimit(2)
                    .privacySensitive(item.hidesTitle)
            case .free(let allDoneCount):
                Text("You're free today")
                    .font(.headline)
                    .widgetAccentable()
                if let allDoneCount {
                    Text("All ^[\(allDoneCount) task](inflect: true) done")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// "12:30 · in 45 min" counts down by itself; the other lines are fixed text.
    private func topLine(_ item: LockScreenItem) -> Text {
        if let date = item.countdownTo, date > entry.date {
            Text(item.topLine) + Text(" · ") + Text("in ") + Text(date, style: .relative)
        } else {
            Text(item.topLine)
        }
    }

    /// An inline widget is a single line of text, so with names hidden the whole line is hidden while locked.
    @ViewBuilder
    private func inline(_ content: LockScreenWidgetContent) -> some View {
        switch content {
        case .next(let item):
            Text(item.inline)
                .privacySensitive(item.hidesTitle)
        case .free:
            Text("You're free today")
        }
    }
}

#Preview("Rectangular", as: .accessoryRectangular) {
    LockScreenWidget()
} timeline: {
    TodayEntry(date: .previewToday(11, 45), snapshot: .preview(timer: nil, data: .nowPreview))
    TodayEntry(date: .previewToday(13), snapshot: .preview(timer: nil, data: .nowPreview))
    TodayEntry(date: .previewToday(18), snapshot: .preview(timer: nil, data: .durationPreview))
    TodayEntry(date: .previewToday(10), snapshot: .preview(timer: nil, data: .nowPreview))
    TodayEntry(date: .previewToday(10), snapshot: .preview(timer: nil, data: .anytimePreview))
    TodayEntry(date: .previewToday(13), snapshot: .preview(timer: nil, data: .allDonePreview))
    TodayEntry(date: .previewToday(13), snapshot: .preview(timer: nil))
    TodayEntry(date: .previewToday(13), snapshot: .preview(timer: nil, data: .nowPreview, hidesTitles: true))
    TodayEntry.failed(.now)
}

#Preview("Inline", as: .accessoryInline) {
    LockScreenWidget()
} timeline: {
    TodayEntry(date: .previewToday(11, 45), snapshot: .preview(timer: nil, data: .nowPreview))
    TodayEntry(date: .previewToday(13), snapshot: .preview(timer: nil, data: .nowPreview))
    TodayEntry(date: .previewToday(18), snapshot: .preview(timer: nil, data: .durationPreview))
    TodayEntry(date: .previewToday(10), snapshot: .preview(timer: nil, data: .nowPreview))
    TodayEntry(date: .previewToday(10), snapshot: .preview(timer: nil, data: .anytimePreview))
    TodayEntry(date: .previewToday(13), snapshot: .preview(timer: nil, data: .allDonePreview))
    TodayEntry(date: .previewToday(13), snapshot: .preview(timer: nil, data: .nowPreview, hidesTitles: true))
    TodayEntry.failed(.now)
}

/// How a locked device draws the rectangular size with "Hide task names on the Lock Screen" on.
#Preview("Names hidden while locked") {
    LockScreenWidgetView(
        entry: TodayEntry(
            date: .previewToday(13), snapshot: .preview(timer: nil, data: .nowPreview, hidesTitles: true))
    )
    .redacted(reason: .privacy)
    .frame(width: 170, height: 76)
}
