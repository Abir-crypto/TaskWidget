import Core
import SwiftUI
import WidgetKit

/// Picks the Now widget's mode for an entry (SPEC F-21).
struct NowWidgetView: View {
    let entry: TodayEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            switch NowWidgetContent(snapshot: snapshot, at: entry.date) {
            case .list(let list):
                NowListView(list: list, date: entry.date, calendar: snapshot.calendar)
            case .timer(let timer):
                NowTimerView(timer: timer)
                    .widgetURL(DeepLink.timer.url)
            }
        } else {
            WidgetFailureView()
        }
    }
}

#Preview("List", as: .systemLarge) {
    NowWidget()
} timeline: {
    TodayEntry(date: .now, snapshot: .preview(timer: nil, data: .nowPreview))
    TodayEntry(date: .now, snapshot: .preview(timer: .previewGeneric(running: true), data: .nowPreview))
    TodayEntry(date: .now, snapshot: .preview(timer: nil))
}

#Preview("Timer", as: .systemLarge) {
    NowWidget()
} timeline: {
    TodayEntry(date: .now, snapshot: .preview(timer: .previewHabit(running: true), habitTitle: "Read"))
    TodayEntry(date: .now, snapshot: .preview(timer: .previewHabit(running: false), habitTitle: "Read"))
}
