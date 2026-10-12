import Core
import Foundation
import Testing

@testable import Tempo

/// SPEC T-40: the missed style changes words, marks and colors only. Statuses, the Missed queries and every Stats
/// number are the same in both styles, and the widgets follow the stored style.
@MainActor
struct MissedStyleBehaviorTests {
    private let clock = TestEnvironment.clock(hour: 9)
    private let store: SwiftDataTaskStore
    private let tasks: TaskManager

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        try store.save(SettingsValue.defaults)
        tasks = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
        clock.now = TestEnvironment.date(2026, 10, 1, 9)
        try tasks.createHabit(
            type: .progress, title: "Stretch", timing: .part(.morning), weekdays: .all, startDay: tasks.today,
            lengthDays: nil, targetMinutes: nil)
        let read = try tasks.createHabit(
            type: .duration, title: "Read", timing: .part(.morning), weekdays: .all, startDay: tasks.today,
            lengthDays: nil, targetMinutes: 30)
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        try tasks.logTime(taskID: read.id, minutes: 10)
        try tasks.createOneTime(title: "Call", date: tasks.today, timing: .part(.morning))
        clock.now = TestEnvironment.date(2026, 10, 6, 13)
    }

    private func snapshot(_ style: MissedStyle) throws -> Snapshot {
        var settings = SettingsValue.defaults
        settings.missedStyle = style
        try store.save(settings)
        return try tasks.snapshot()
    }

    @Test func statusesQueriesAndStatsAreTheSameInBothStyles() throws {
        let gentle = try snapshot(.gentle)
        let strict = try snapshot(.strict)
        #expect(
            MissedQueries.missedToday(in: gentle, now: clock.now).map(\.id)
                == MissedQueries.missedToday(in: strict, now: clock.now).map(\.id))
        #expect(
            MissedQueries.missedEarlier(in: gentle, now: clock.now).map(\.id)
                == MissedQueries.missedEarlier(in: strict, now: clock.now).map(\.id))
        #expect(!MissedQueries.missedToday(in: gentle, now: clock.now).isEmpty)
        for kind in StatsRangeKind.allCases {
            let range = StatsRange.containing(tasks.today, kind: kind, calendar: gentle.calendar)
            #expect(
                StatsCalculator(snapshot: gentle, now: clock.now).stats(for: range)
                    == StatsCalculator(snapshot: strict, now: clock.now).stats(for: range))
        }
        let gentlePlan = DayPlan(day: tasks.today, snapshot: gentle, now: clock.now)
        let strictPlan = DayPlan(day: tasks.today, snapshot: strict, now: clock.now)
        #expect(gentlePlan.items.map(\.status) == strictPlan.items.map(\.status))
    }

    @Test func widgetsFollowTheStoredStyle() throws {
        for style in MissedStyle.allCases {
            _ = try snapshot(style)
            let widget = try SnapshotLoader.load(store: store, deviceState: TestEnvironment.deviceState(), clock: clock)
            #expect(DayWidgetContent(snapshot: widget, at: clock.now).missedStyle == style)
            guard case .list(let list) = NowWidgetContent(snapshot: widget, at: clock.now) else {
                Issue.record("Expected list mode")
                return
            }
            #expect(list.missedStyle == style)
            #expect(list.missedCount == 3)
        }
    }

    /// SPEC F-30: the words and marks for each style, with an icon or text as well as a color (F-17).
    @Test func wordsAndMarks() {
        #expect(MissedStyle.strict.statusTitle == "Missed")
        #expect(MissedStyle.gentle.statusTitle == "Not done")
        #expect(MissedStyle.strict.count(14) == "14 missed")
        #expect(MissedStyle.gentle.count(14) == "14 not done")
        #expect(MissedStyle.strict.todayFooter(2) == "2 missed today ›")
        #expect(MissedStyle.gentle.todayFooter(2) == "2 not done today ›")
        #expect(MissedStyle.gentle.mostMissed("Evening") == "Most often not done: Evening")
        #expect(MissedStyle.gentle.recentDaysTitle == "Recent days not done")
        #expect(MissedStyle.gentle.todayEmpty == "Nothing left undone today")
        #expect(MissedStyle.gentle.earlierEmpty == "Nothing undone before today")
        #expect(MissedStyle.gentle.filtersEmpty == "No tasks match these filters")
        #expect(DayMark.missed.systemImage(.strict) == "xmark.circle")
        #expect(DayMark.missed.systemImage(.gentle) == "minus.circle")
        #expect(MissedStyle.gentle.showsBadgeAndPopup == false)
        #expect(MissedStyle.strict.showsBadgeAndPopup)
    }
}
