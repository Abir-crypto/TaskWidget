import Foundation

/// Everything the Stats screen shows for one range (SPEC F-14).
public struct StatsSnapshot: Hashable, Sendable {
    public let range: StatsRange

    // 1. Overview
    /// The habits' completion rate in the range.
    public let rate: CompletionRate
    /// The change from the previous range in percentage points; `nil` when the previous range has no counted days.
    public let change: Int?
    /// One-time tasks dated in the range (up to today) that have a completion.
    public let oneTimeCompleted: Int
    /// Minutes logged across every habit in the range.
    public let totalMinutes: Int

    // 2. Completion chart
    /// One entry per day of the range: habit days done out of counted.
    public let days: [DayRate]
    /// For a year: one entry per month. Empty for weeks and months.
    public let months: [MonthRate]

    // 3. Time
    public let time: [HabitTime]

    // 4. Parts of the day
    public let parts: [PartRate]
    /// The part (or Anytime) with the lowest rate among those with at least 3 counted occurrences.
    public let mostMissed: MissedPartFilter?

    // 5. Streaks, highest current first
    public let streaks: [HabitStreak]

    // 6. Habits
    public let habits: [HabitRate]

    public init(
        range: StatsRange, rate: CompletionRate, change: Int?, oneTimeCompleted: Int, totalMinutes: Int,
        days: [DayRate], months: [MonthRate], time: [HabitTime], parts: [PartRate], mostMissed: MissedPartFilter?,
        streaks: [HabitStreak], habits: [HabitRate]
    ) {
        self.range = range
        self.rate = rate
        self.change = change
        self.oneTimeCompleted = oneTimeCompleted
        self.totalMinutes = totalMinutes
        self.days = days
        self.months = months
        self.time = time
        self.parts = parts
        self.mostMissed = mostMissed
        self.streaks = streaks
        self.habits = habits
    }

    /// Whether there are any habits to show stats for (SPEC F-24).
    public var hasHabits: Bool { !habits.isEmpty }
}

/// A day's habit completion.
public struct DayRate: Hashable, Sendable {
    public let day: DayKey
    public let rate: CompletionRate

    public init(day: DayKey, rate: CompletionRate) {
        self.day = day
        self.rate = rate
    }
}

/// A month's habit completion, for the Year chart.
public struct MonthRate: Hashable, Sendable {
    public let year: Int
    public let month: Int
    public let rate: CompletionRate

    public init(year: Int, month: Int, rate: CompletionRate) {
        self.year = year
        self.month = month
        self.rate = rate
    }
}

/// A duration habit's minutes in a range against its goal for the range.
public struct HabitTime: Hashable, Sendable {
    public let task: TaskValue
    public let progress: GoalProgress

    public init(task: TaskValue, progress: GoalProgress) {
        self.task = task
        self.progress = progress
    }
}

/// The completion rate of one part of the day, or Anytime.
public struct PartRate: Hashable, Sendable {
    public let part: MissedPartFilter
    public let rate: CompletionRate

    public init(part: MissedPartFilter, rate: CompletionRate) {
        self.part = part
        self.rate = rate
    }
}

/// A habit's streaks.
public struct HabitStreak: Hashable, Sendable {
    public let task: TaskValue
    public let streak: Streak

    public init(task: TaskValue, streak: Streak) {
        self.task = task
        self.streak = streak
    }
}

/// A habit's completion rate in a range.
public struct HabitRate: Hashable, Sendable {
    public let task: TaskValue
    public let rate: CompletionRate

    public init(task: TaskValue, rate: CompletionRate) {
        self.task = task
        self.rate = rate
    }
}
