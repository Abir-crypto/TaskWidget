import Foundation

/// A day laid out as the app and widgets show it: Morning, Noon, Evening, Night, then Anytime (SPEC F-10).
public struct DayPlan: Hashable, Sendable {
    public let day: DayKey
    public let sections: [DaySection]

    public init(day: DayKey, sections: [DaySection]) {
        self.day = day
        self.sections = sections
    }

    /// Builds the plan for `day` as of `now`.
    public init(day: DayKey, snapshot: Snapshot, now: Date) {
        let local = LocalTime(now, calendar: snapshot.calendar)
        let parts = snapshot.parts
        let occurrences = DayOrder.sorted(snapshot.occurrences(on: day), parts: parts)
        let items = occurrences.map { occurrence in
            let isDuration = occurrence.type == .duration
            return DayItem(
                occurrence: occurrence,
                status: snapshot.status(of: occurrence, now: now),
                minutes: isDuration ? snapshot.statusRules.minutes(of: occurrence) : 0,
                targetMinutes: isDuration ? occurrence.schedule.targetMinutes : nil)
        }

        func phase(for window: Range<Int>, isAnytime: Bool) -> DaySectionPhase {
            if day < local.day { return .past }
            if day > local.day { return .future }
            if isAnytime { return .anytime }
            if window.upperBound <= local.minute { return .ended }
            if window.lowerBound <= local.minute { return .current }
            return .upcoming
        }

        var sections = DayPart.allCases.map { part in
            let window = parts.window(of: part)
            return DaySection(
                part: part,
                phase: phase(for: window, isAnytime: false),
                window: window,
                items: items.filter { $0.occurrence.part(parts: parts) == part })
        }
        sections.append(
            DaySection(
                part: nil,
                phase: phase(for: 0..<DayKey.minutesPerDay, isAnytime: true),
                window: 0..<DayKey.minutesPerDay,
                items: items.filter { $0.occurrence.part(parts: parts) == nil }))
        self.day = day
        self.sections = sections
    }

    /// Every item, in display order.
    public var items: [DayItem] { sections.flatMap(\.items) }

    public var isEmpty: Bool { sections.allSatisfy { $0.items.isEmpty } }

    /// The section in progress, if the plan is for today and a part has started.
    public var currentSection: DaySection? { sections.first { $0.phase == .current } }

    public func section(for part: DayPart?) -> DaySection? {
        sections.first { $0.part == part }
    }
}
