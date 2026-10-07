import Core
import Foundation
import WidgetKit

/// The one timeline provider every widget uses (ios.md §9). `WidgetTimelinePlan` decides the entries and when
/// to ask again; this wraps them for WidgetKit.
struct TodayTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: Date(), snapshot: .empty(calendar: Calendar.autoupdatingCurrent))
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(TodayEntry(date: Date(), snapshot: try? SnapshotLoader.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let plan = WidgetTimelinePlan.make(now: Date()) { try SnapshotLoader.load() }
        completion(
            Timeline(
                entries: plan.moments.map { TodayEntry(date: $0, snapshot: plan.snapshot) },
                policy: .after(plan.refreshAfter)))
    }
}
