import Foundation

/// The next-task rule shared by the Focus widget and the Lock Screen widgets (SPEC §5.6).
public enum NextTaskRule {
    /// Fixed-time tasks within this many minutes come first (rule 1), and fixed-time tasks further ahead than
    /// this don't count as the current part's (rule 2).
    public static let soonMinutes = 60

    /// The next item now, or `nil` for "You're free today".
    public static func next(in snapshot: Snapshot, now: Date) -> NextTask? {
        pick(
            from: candidates(in: snapshot, now: now), now: LocalTime(now, calendar: snapshot.calendar),
            parts: snapshot.parts)
    }

    /// The Focus widget's "Then:" line: the rule applied again with the next item removed.
    public static func then(in snapshot: Snapshot, now: Date) -> NextTask? {
        let local = LocalTime(now, calendar: snapshot.calendar)
        var remaining = candidates(in: snapshot, now: now)
        guard let first = pick(from: remaining, now: local, parts: snapshot.parts) else { return nil }
        remaining.removeAll { $0.id == first.occurrence.id }
        return pick(from: remaining, now: local, parts: snapshot.parts)
    }

    /// Today's occurrences that are neither Done, Missed nor Short, in creation order.
    public static func candidates(in snapshot: Snapshot, now: Date) -> [Occurrence] {
        let today = DayKey(now, calendar: snapshot.calendar)
        return snapshot.occurrences(on: today).filter { snapshot.status(of: $0, now: now).isPending }
    }

    /// The part in progress, or `nil` before Morning's start (D-061).
    public static func currentPart(at minute: Int, parts: PartSettings) -> DayPart? {
        minute < parts.morningStart ? nil : parts.part(containing: minute)
    }

    /// SPEC §5.6, rules 1–5, over candidates given in creation order.
    public static func pick(from candidates: [Occurrence], now: LocalTime, parts: PartSettings) -> NextTask? {
        let current = currentPart(at: now.minute, parts: parts)
        let fixed = candidates.compactMap { occurrence in occurrence.timing.fixedMinute.map { (occurrence, $0) } }

        // 1. A fixed-time candidate whose time is now or within the next 60 minutes, earliest first.
        let soon = fixed.filter { $0.1 >= now.minute && $0.1 <= now.minute + soonMinutes }
        if let (occurrence, minute) = earliest(soon) {
            return NextTask(occurrence: occurrence, kind: .fixed(minute: minute))
        }

        // 2. A candidate in the current part: fixed times already passed (earliest first), then part-of-day tasks
        //    in creation order. Fixed times more than 60 minutes ahead don't count here.
        if let current {
            let passed = fixed.filter { $0.1 < now.minute && parts.part(containing: $0.1) == current }
            if let (occurrence, _) = earliest(passed) {
                return NextTask(occurrence: occurrence, kind: .currentPart(current))
            }
            if let occurrence = candidates.first(where: { $0.timing == .part(current) }) {
                return NextTask(occurrence: occurrence, kind: .currentPart(current))
            }
        }

        // 3. The earliest coming item: fixed times at their time, later parts' tasks at their part's start.
        //    On a tie, fixed time wins, then creation order.
        var coming: [(occurrence: Occurrence, minute: Int, fixedFirst: Int, order: Int, kind: NextTaskKind)] = []
        for (order, occurrence) in candidates.enumerated() {
            switch occurrence.timing {
            case .fixed(let minute):
                coming.append((occurrence, minute, 0, order, .fixed(minute: minute)))
            case .part(let part) where current.map({ part > $0 }) ?? true:
                coming.append((occurrence, parts.start(of: part), 1, order, .laterPart(part)))
            case .part, .anytime:
                continue
            }
        }
        if let best = coming.min(by: { ($0.minute, $0.fixedFirst, $0.order) < ($1.minute, $1.fixedFirst, $1.order) }) {
            return NextTask(occurrence: best.occurrence, kind: best.kind)
        }

        // 4. An Anytime candidate, in creation order.
        if let occurrence = candidates.first(where: { $0.timing == .anytime }) {
            return NextTask(occurrence: occurrence, kind: .anytime)
        }

        // 5. Nothing: "You're free today".
        return nil
    }

    /// The earliest fixed time; ties keep creation order.
    private static func earliest(_ items: [(Occurrence, Int)]) -> (Occurrence, Int)? {
        items.enumerated().min { ($0.element.1, $0.offset) < ($1.element.1, $1.offset) }?.element
    }
}
