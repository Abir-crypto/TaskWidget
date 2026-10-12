import Foundation

/// Plans the notifications (SPEC §5.9, F-07): what to send in the coming hours, judged on the current data.
public enum ReminderPlanner {
    /// How far ahead to plan; at least 48 hours must always be covered (SPEC F-07).
    public static let horizon: TimeInterval = 72 * 60 * 60
    /// Platforms cap pending notifications; iOS allows 64, so 60 leaves room (ios.md §10).
    public static let defaultLimit = 60

    /// The running timer, for the alert.
    public struct RunningTimer: Sendable {
        public let state: TimerState
        public let habitTitle: String?

        public init(state: TimerState, habitTitle: String?) {
            self.state = state
            self.habitTitle = habitTitle
        }
    }

    /// Every notification due after `now` and within the horizon, earliest first, trimmed to `limit`.
    public static func plan(
        snapshot: Snapshot, now: Date, timer: RunningTimer? = nil, limit: Int = defaultLimit
    ) -> [PlannedNotification] {
        let calendar = snapshot.calendar
        let settings = snapshot.settings
        let end = now.addingTimeInterval(horizon)
        let firstDay = DayKey(now, calendar: calendar)
        let lastDay = DayKey(end, calendar: calendar)
        var plan: [PlannedNotification] = []

        for day in firstDay.through(lastDay, in: calendar) {
            let candidates = snapshot.occurrences(on: day).filter { !snapshot.statusRules.isDone($0) }
            let ordered = DayOrder.sorted(candidates, parts: snapshot.parts)
            let anytime = ordered.filter { $0.part(parts: snapshot.parts) == nil }

            for part in DayPart.allCases {
                let items = ordered.filter { $0.part(parts: snapshot.parts) == part }
                let start = day.date(atMinute: settings.parts.start(of: part), in: calendar)
                let partEnd = day.date(atMinute: settings.parts.end(of: part), in: calendar)

                // Part starts: for Morning, Anytime tasks count too.
                let partAnytime = part == .morning ? anytime : []
                // Each part's summary has its own switch; only Morning's is on by default (D-109).
                if settings.partStartSummaries.contains(part), !items.isEmpty || !partAnytime.isEmpty {
                    plan.append(
                        PlannedNotification(
                            id: "part-start.\(day.rawValue).\(part.rawValue)", fireDate: start,
                            content: .partStart(
                                day: day, part: part, items: items.map { item($0, snapshot) },
                                anytime: partAnytime.map { item($0, snapshot) })))
                }

                // Ending soon: the lead time before the part ends, but never before it starts.
                if settings.notifyEndingSoon, !items.isEmpty {
                    let fire = max(start, partEnd.addingTimeInterval(TimeInterval(-settings.endingSoonLead * 60)))
                    plan.append(
                        PlannedNotification(
                            id: "ending-soon.\(day.rawValue).\(part.rawValue)", fireDate: fire,
                            content: .endingSoon(
                                day: day, part: part, minutesLeft: Int(partEnd.timeIntervalSince(fire) / 60),
                                items: items.map { item($0, snapshot) })))
                }
            }

            // Fixed time: the lead time before each fixed-time task that isn't done.
            if settings.notifyFixed {
                for occurrence in ordered {
                    guard let minute = occurrence.timing.fixedMinute else { continue }
                    let fire = day.date(atMinute: minute, in: calendar)
                        .addingTimeInterval(TimeInterval(-settings.fixedLead * 60))
                    plan.append(
                        PlannedNotification(
                            id: "fixed.\(occurrence.task.id.uuidString.lowercased()).\(day.rawValue)", fireDate: fire,
                            content: .fixed(day: day, item: item(occurrence, snapshot), leadMinutes: settings.fixedLead)
                        ))
                }
            }

            // Recap: when the day will still have tasks that aren't done, split by their status at the recap time.
            if settings.notifyRecap, !ordered.isEmpty {
                let fire = day.date(atMinute: settings.recapMinute, in: calendar)
                let missed = ordered.filter { snapshot.status(of: $0, now: fire).countsAsMissed }
                let open = ordered.filter { snapshot.status(of: $0, now: fire).isPending }
                plan.append(
                    PlannedNotification(
                        id: "recap.\(day.rawValue)", fireDate: fire,
                        content: .recap(
                            day: day, missed: missed.map { item($0, snapshot) }, open: open.map { item($0, snapshot) }))
                )
            }
        }

        // The running timer's next alert.
        if settings.notifyTimer, let timer,
            let fire = TimerRules.nextAlert(timer.state, periodMinutes: settings.timerAlertMinutes, now: now),
            let segmentStart = timer.state.segmentStart
        {
            plan.append(
                PlannedNotification(
                    id: "timer-alert", fireDate: fire,
                    content: .timerAlert(
                        habitTitle: timer.habitTitle, runningMinutes: Int(fire.timeIntervalSince(segmentStart) / 60))))
        }

        return Array(
            plan.filter { $0.fireDate > now && $0.fireDate <= end }
                .sorted { ($0.fireDate, $0.id) < ($1.fireDate, $1.id) }
                .prefix(limit))
    }

    private static func item(_ occurrence: Occurrence, _ snapshot: Snapshot) -> ReminderItem {
        let isDuration = occurrence.type == .duration
        return ReminderItem(
            taskID: occurrence.task.id, title: occurrence.task.title, fixedMinute: occurrence.timing.fixedMinute,
            minutes: isDuration ? snapshot.statusRules.minutes(of: occurrence) : nil,
            targetMinutes: isDuration ? occurrence.schedule.targetMinutes : nil)
    }
}
