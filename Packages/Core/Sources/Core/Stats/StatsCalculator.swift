import Foundation

/// The stats formulas (SPEC §5.7), for the Stats screen and Habit detail.
///
/// Ranges count up to and including today. A habit day today is counted only once it's Done, Missed or
/// Short; Upcoming and Open days don't count yet.
public struct StatsCalculator: Sendable {
    public let snapshot: Snapshot
    public let now: Date
    public let today: DayKey

    public init(snapshot: Snapshot, now: Date) {
        self.snapshot = snapshot
        self.now = now
        self.today = DayKey(now, calendar: snapshot.calendar)
    }

    private var calendar: Calendar { snapshot.calendar }
    private var engine: ScheduleEngine { snapshot.engine }
    private var durationMath: DurationMath { DurationMath(snapshot: snapshot) }

    /// Live habits, in creation order.
    public var habits: [TaskValue] { engine.tasks.filter(\.type.isHabit) }

    /// The day the first live task was created; the Stats screen can't go back before it.
    public var firstDay: DayKey? {
        engine.tasks.map(\.createdAt).min().map { DayKey($0, calendar: calendar) }
    }

    // MARK: Counting

    /// Whether an occurrence counts: on a past day always, today only once its status is final.
    private func counts(_ occurrence: Occurrence) -> Status? {
        guard occurrence.day <= today else { return nil }
        let status = snapshot.status(of: occurrence, now: now)
        return status.isFinal ? status : nil
    }

    /// The last day of `first…last` that can count: never after today.
    private func countingEnd(_ last: DayKey) -> DayKey { min(last, today) }

    /// A habit's counted days in a range: done out of counted.
    public func rate(of task: TaskValue, from first: DayKey, through last: DayKey) -> CompletionRate {
        guard first <= countingEnd(last) else { return .empty }
        var done = 0
        var counted = 0
        for occurrence in engine.occurrences(of: task, from: first, through: countingEnd(last)) {
            guard let status = counts(occurrence) else { continue }
            counted += 1
            if status == .done { done += 1 }
        }
        return CompletionRate(done: done, counted: counted)
    }

    /// Every habit's counted days in a range, added together.
    public func habitsRate(from first: DayKey, through last: DayKey) -> CompletionRate {
        habits.reduce(.empty) { $0 + rate(of: $1, from: first, through: last) }
    }

    /// The statuses of a habit's scheduled days in a range, for week dots and the month calendar. Days that
    /// aren't scheduled are missing from the result.
    public func statuses(of task: TaskValue, from first: DayKey, through last: DayKey) -> [DayKey: Status] {
        var result: [DayKey: Status] = [:]
        for occurrence in engine.occurrences(of: task, from: first, through: last) {
            result[occurrence.day] = snapshot.status(of: occurrence, now: now)
        }
        return result
    }

    // MARK: Streaks

    /// The run of consecutive done scheduled days, counting back from the most recent counted day, and the
    /// longest run ever. Unscheduled days are skipped, and today doesn't break it while Upcoming or Open.
    public func streak(of task: TaskValue) -> Streak {
        guard let start = task.startDay, start <= today else { return .zero }
        let end = min(task.lastDay(in: calendar) ?? today, today)
        guard start <= end else { return .zero }
        var best = 0
        var run = 0
        for occurrence in engine.occurrences(of: task, from: start, through: end) {
            guard let status = counts(occurrence) else { continue }
            if status == .done {
                run += 1
                best = max(best, run)
            } else {
                run = 0
            }
        }
        return Streak(current: run, best: best)
    }

    // MARK: Stats screen

    /// Every card of the Stats screen for a range (SPEC F-14, §5.7).
    public func stats(for range: StatsRange) -> StatsSnapshot {
        let overall = habitsRate(from: range.first, through: range.last)
        let previous = range.previous(in: calendar)
        let previousRate = habitsRate(from: previous.first, through: previous.last)
        let change: Int? =
            if let current = overall.percent, let before = previousRate.percent { current - before } else { nil }

        let liveHabits = habits.filter { isLive($0, in: range) }
        let streaks = liveHabits.map { HabitStreak(task: $0, streak: streak(of: $0)) }
            .enumerated()
            .sorted { ($1.element.streak.current, $0.offset) < ($0.element.streak.current, $1.offset) }
            .map(\.element)

        let partRates = partRates(from: range.first, through: range.last)
        return StatsSnapshot(
            range: range,
            rate: overall,
            change: change,
            oneTimeCompleted: oneTimeCompleted(from: range.first, through: range.last),
            totalMinutes: totalMinutes(from: range.first, through: range.last),
            days: range.days(in: calendar).map { DayRate(day: $0, rate: habitsRate(from: $0, through: $0)) },
            months: range.kind == .year ? monthRates(year: range.first.year) : [],
            time: liveHabits.filter { $0.type == .duration }.map {
                habitTime($0, from: range.first, through: range.last)
            },
            parts: partRates,
            mostMissed: mostMissed(partRates),
            streaks: streaks,
            habits: liveHabits.map { HabitRate(task: $0, rate: rate(of: $0, from: range.first, through: range.last)) }
        )
    }

    /// One-time tasks whose date is in the range (up to today) and that have a completion.
    public func oneTimeCompleted(from first: DayKey, through last: DayKey) -> Int {
        let end = countingEnd(last)
        return engine.tasks.filter { task in
            guard task.type == .oneTime, let date = task.date, first <= date, date <= end else { return false }
            return snapshot.activity.isCompleted(taskID: task.id, day: date)
        }.count
    }

    /// The minutes logged across every habit and day in the range.
    public func totalMinutes(from first: DayKey, through last: DayKey) -> Int {
        habits.filter { $0.type == .duration }.reduce(0) { $0 + durationMath.total(of: $1, from: first, through: last) }
    }

    /// A duration habit's minutes in the range against the sum of its targets over every scheduled day of the
    /// range, including days still to come.
    public func habitTime(_ task: TaskValue, from first: DayKey, through last: DayKey) -> HabitTime {
        HabitTime(
            task: task,
            progress: GoalProgress(
                minutes: durationMath.total(of: task, from: first, through: last),
                goal: durationMath.goal(of: task, from: first, through: last)))
    }

    /// Done out of counted for each part and for Anytime, over every type of occurrence whose status is final.
    /// Fixed-time tasks count in their part.
    public func partRates(from first: DayKey, through last: DayKey) -> [PartRate] {
        var done: [MissedPartFilter: Int] = [:]
        var counted: [MissedPartFilter: Int] = [:]
        let end = countingEnd(last)
        if first <= end {
            for occurrence in engine.occurrences(from: first, through: end) {
                guard let status = counts(occurrence) else { continue }
                let part = MissedPartFilter(occurrence.part(parts: snapshot.parts))
                counted[part, default: 0] += 1
                if status == .done { done[part, default: 0] += 1 }
            }
        }
        return MissedPartFilter.allCases.map {
            PartRate(part: $0, rate: CompletionRate(done: done[$0] ?? 0, counted: counted[$0] ?? 0))
        }
    }

    /// The part with the lowest rate among those with at least 3 counted occurrences; on a tie, the earlier one.
    public func mostMissed(_ rates: [PartRate]) -> MissedPartFilter? {
        rates.filter { $0.rate.counted >= 3 }
            .min { lhs, rhs in
                // Compare done/counted exactly: lhs.done / lhs.counted < rhs.done / rhs.counted.
                lhs.rate.done * rhs.rate.counted < rhs.rate.done * lhs.rate.counted
            }?
            .part
    }

    /// The twelve months of a year, each with its habits' rate.
    public func monthRates(year: Int) -> [MonthRate] {
        (1...12).map { month in
            let range = StatsRange.containing(
                DayKey(year: year, month: month, day: 1), kind: .month, calendar: calendar)
            return MonthRate(year: year, month: month, rate: habitsRate(from: range.first, through: range.last))
        }
    }

    /// Whether a habit is live on any day of the range.
    private func isLive(_ task: TaskValue, in range: StatsRange) -> Bool {
        guard let start = task.startDay, start <= range.last else { return false }
        if let last = task.lastDay(in: calendar), last < range.first || last < start { return false }
        return true
    }
}
