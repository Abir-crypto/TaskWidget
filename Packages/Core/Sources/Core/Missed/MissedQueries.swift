import Foundation

/// Missed today, missed earlier and unseen (SPEC §5.8).
public enum MissedQueries {
    /// Today's occurrences that are Missed or Short, in day order.
    public static func missedToday(in snapshot: Snapshot, now: Date) -> [MissedItem] {
        let today = DayKey(now, calendar: snapshot.calendar)
        let items = snapshot.occurrences(on: today).compactMap { item(for: $0, in: snapshot, now: now) }
        return ordered(items, parts: snapshot.parts)
    }

    /// Occurrences before today that are Missed or Short, filtered and sorted. Ended habits are included;
    /// deleted tasks never appear.
    public static func missedEarlier(in snapshot: Snapshot, now: Date, filter: MissedFilter = .default) -> [MissedItem]
    {
        let calendar = snapshot.calendar
        let today = DayKey(now, calendar: calendar)
        let yesterday = today.adding(days: -1, in: calendar)
        let range = dateBounds(filter.dateRange, today: today, calendar: calendar)
        let last = min(range.last ?? yesterday, yesterday)

        var items: [MissedItem] = []
        for task in snapshot.engine.tasks {
            if let taskID = filter.taskID, task.id != taskID { continue }
            guard filter.types.contains(task.type) else { continue }
            let first: DayKey
            if task.type.isHabit {
                guard let start = task.startDay else { continue }
                first = max(start, range.first ?? start)
            } else {
                guard let date = task.date else { continue }
                first = max(date, range.first ?? date)
            }
            let taskLast =
                task.type.isHabit ? min(task.lastDay(in: calendar) ?? last, last) : min(task.date ?? last, last)
            guard first <= taskLast else { continue }
            for occurrence in snapshot.engine.occurrences(of: task, from: first, through: taskLast) {
                guard filter.parts.contains(MissedPartFilter(occurrence.part(parts: snapshot.parts))) else { continue }
                if let item = item(for: occurrence, in: snapshot, now: now) { items.append(item) }
            }
        }
        let byDay = Dictionary(grouping: items, by: \.day)
        let days = byDay.keys.sorted(by: filter.sort == .newestFirst ? (>) : (<))
        return days.flatMap { ordered(byDay[$0] ?? [], parts: snapshot.parts) }
    }

    /// Missed today, minus the ones the popup has already shown. A seen list from another day counts as empty.
    public static func unseen(in snapshot: Snapshot, now: Date, seen: MissedSeenList?) -> [MissedItem] {
        let today = DayKey(now, calendar: snapshot.calendar)
        let seenIDs = seen?.day == today ? seen?.occurrenceIDs ?? [] : []
        return missedToday(in: snapshot, now: now).filter { !seenIDs.contains($0.id) }
    }

    /// The first and last day of a date range, either of which may be open.
    public static func dateBounds(
        _ range: MissedDateRange, today: DayKey, calendar: Calendar
    ) -> (first: DayKey?, last: DayKey?) {
        switch range {
        case .all:
            return (nil, nil)
        case .thisWeek:
            let first = today.startOfWeek(in: calendar)
            return (first, first.adding(days: 6, in: calendar))
        case .thisMonth:
            let first = today.startOfMonth
            let nextMonth = first.adding(days: 31, in: calendar).startOfMonth
            return (first, nextMonth.adding(days: -1, in: calendar))
        case .custom(let first, let last):
            return (min(first, last), max(first, last))
        }
    }

    private static func item(for occurrence: Occurrence, in snapshot: Snapshot, now: Date) -> MissedItem? {
        let status = snapshot.status(of: occurrence, now: now)
        guard status.countsAsMissed else { return nil }
        let isDuration = occurrence.type == .duration
        return MissedItem(
            occurrence: occurrence,
            status: status,
            minutes: isDuration ? snapshot.statusRules.minutes(of: occurrence) : 0,
            targetMinutes: isDuration ? occurrence.schedule.targetMinutes : nil)
    }

    private static func ordered(_ items: [MissedItem], parts: PartSettings) -> [MissedItem] {
        let byID = Dictionary(items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return DayOrder.sorted(items.map(\.occurrence), parts: parts).compactMap { byID[$0.id] }
    }
}
