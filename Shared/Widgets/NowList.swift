import Core
import Foundation

/// List mode (SPEC F-21): the current part, then the next part with tasks, then Anytime, as many as fit.
struct NowList: Hashable {
    struct Group: Hashable {
        let section: DaySection
        let items: [DayItem]
    }

    /// The groups shown, in order. The first one is the header's part.
    let groups: [Group]
    /// Tasks that didn't fit ("+N more").
    let hiddenCount: Int
    /// Today's Missed and Short tasks, for the footer.
    let missedCount: Int
    /// A generic timer, shown as a display-only line; ▶ buttons are hidden while it exists.
    let genericTimer: TimerClockValue?
    /// Whether ▶ can show: no timer of any kind exists.
    let canStartTimers: Bool
    /// Nothing is left today: "You're free today".
    let isFree: Bool
    /// Today has no tasks at all: "No tasks today", and tapping opens the editor.
    let hasNoTasks: Bool

    init(snapshot: WidgetSnapshot, at date: Date) {
        let plan = snapshot.plan(at: date)
        let current = plan.sections.firstIndex { $0.phase == .current }
        let start = current ?? plan.sections.firstIndex { $0.phase == .upcoming } ?? plan.sections.count - 1
        let partSections = plan.sections.indices.filter { $0 >= start && plan.sections[$0].part != nil }
            .map { plan.sections[$0] }
        let anytime = plan.section(for: nil)

        // The current part when it has tasks, otherwise the next part with tasks; then the part after that.
        var ordered: [DaySection] = []
        let withTasks = partSections.filter { !$0.items.isEmpty }
        if let first = withTasks.first { ordered.append(first) }
        if withTasks.count > 1 { ordered.append(withTasks[1]) }
        if let anytime, !anytime.items.isEmpty { ordered.append(anytime) }

        var groups: [Group] = []
        var rows = 0
        var hidden = 0
        for section in ordered {
            // The first group's header is the widget's header, so it doesn't take a row.
            let headerRows = groups.isEmpty ? 0 : 1
            let room = NowWidgetContent.maximumRows - rows - headerRows
            guard room > 0 else {
                hidden += section.items.count
                continue
            }
            let shown = Array(section.items.prefix(room))
            hidden += section.items.count - shown.count
            groups.append(Group(section: section, items: shown))
            rows += headerRows + shown.count
        }

        let remaining = (partSections + [anytime].compactMap { $0 }).flatMap(\.items).filter { $0.status.isPending }
        self.groups = groups
        self.hiddenCount = hidden
        self.missedCount = plan.items.filter { $0.status.countsAsMissed }.count
        self.genericTimer = snapshot.timer.flatMap { $0.kind == .generic ? TimerClockValue(state: $0) : nil }
        self.canStartTimers = snapshot.timer == nil
        self.isFree = remaining.isEmpty
        self.hasNoTasks = plan.isEmpty
    }

    /// Pending tasks in the header's part ("N left").
    var leftCount: Int {
        groups.first?.items.filter { $0.status.isPending }.count ?? 0
    }
}
