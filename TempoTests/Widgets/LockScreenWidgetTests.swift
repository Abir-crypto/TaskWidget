import Core
import Foundation
import Testing

@testable import Tempo

/// SPEC T-27: both Lock Screen sizes show every situation in the F-22 table, and titles can be hidden.
@MainActor
struct LockScreenWidgetTests {
    private let clock = TestEnvironment.clock(hour: 9)
    private let store: SwiftDataTaskStore
    private let widgets = WidgetReloadCounter()
    private let tasks: TaskManager

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        try store.save(SettingsValue.defaults)
        tasks = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: widgets))
    }

    private func content(at hour: Int, _ minute: Int = 0) throws -> LockScreenWidgetContent {
        let snapshot = try SnapshotLoader.load(store: store, deviceState: TestEnvironment.deviceState(), clock: clock)
        return LockScreenWidgetContent(snapshot: snapshot, at: TestEnvironment.date(2026, 10, 6, hour, minute))
    }

    private func item(at hour: Int, _ minute: Int = 0) throws -> LockScreenItem? {
        guard case .next(let item) = try content(at: hour, minute) else { return nil }
        return item
    }

    @discardableResult
    private func make(_ title: String, _ timing: Timing) throws -> TaskValue {
        clock.advance(by: 1)
        return try tasks.createOneTime(title: title, date: tasks.today, timing: timing)
    }

    private func read(_ timing: Timing, logged: Int = 10) throws {
        let read = try tasks.createHabit(
            type: .duration, title: "Read", timing: timing, weekdays: .all, startDay: tasks.today, lengthDays: nil,
            targetMinutes: 30)
        try tasks.logTime(taskID: read.id, minutes: logged)
    }

    private func time(_ minute: Int) -> String { TimeOfDayFormatter.string(minute: minute) }

    @Test func fixedTimeTaskComingUp() throws {
        let interview = try make("Interview", .fixed(minute: 750))
        let item = try #require(try item(at: 11, 45))
        #expect(item.topLine == time(750))
        #expect(item.countdownTo == TestEnvironment.date(2026, 10, 6, 12, 30))
        #expect(item.title == "Interview")
        #expect(item.inline == "Next: Interview at \(time(750))")
        #expect(DeepLink(url: item.url) == .today(day: TestEnvironment.today, taskID: interview.id))
    }

    @Test func partOfDayTaskOpenNow() throws {
        try make("Call the bank", .part(.noon))
        let item = try #require(try item(at: 13))
        #expect(item.topLine == "Noon · until \(time(1020))")
        #expect(item.countdownTo == nil)
        #expect(item.title == "Call the bank")
        #expect(item.inline == "Noon: Call the bank")
    }

    @Test func durationHabitShowsItsProgress() throws {
        try read(.part(.evening))
        let now = try #require(try item(at: 18))
        #expect(now.topLine == "Evening · 10 of 30 min")
        #expect(now.title == "Read")
        #expect(now.inline == "Evening: Read")
        // In a later part, the progress still takes the place of "from 17:00" (D-092).
        let later = try #require(try item(at: 13))
        #expect(later.topLine == "Evening · 10 of 30 min")
        #expect(later.inline == "Evening: Read")
    }

    @Test func fixedTimeDurationHabit() throws {
        try read(.fixed(minute: 750))
        let item = try #require(try item(at: 12))
        #expect(item.topLine == "\(time(750)) · 10 of 30 min")
        #expect(item.countdownTo == nil)
        #expect(item.inline == "Next: Read at \(time(750))")
    }

    @Test func anytimeDurationHabit() throws {
        try read(.anytime, logged: 5)
        let item = try #require(try item(at: 12))
        #expect(item.topLine == "Anytime · 5 of 30 min")
        #expect(item.inline == "Anytime: Read")
    }

    @Test func taskInALaterPart() throws {
        try make("Gym", .part(.evening))
        let item = try #require(try item(at: 13))
        #expect(item.topLine == "Evening · from \(time(1020))")
        #expect(item.inline == "Evening: Gym")
    }

    @Test func anytimeTask() throws {
        try make("Renew passport", .anytime)
        let item = try #require(try item(at: 22))
        #expect(item.topLine == "Anytime")
        #expect(item.countdownTo == nil)
        #expect(item.inline == "Anytime: Renew passport")
    }

    @Test func freeWhenNothingIsLeft() throws {
        #expect(try content(at: 13) == .free(allDoneCount: nil))
        let call = try make("Call", .part(.noon))
        let gym = try make("Gym", .part(.evening))
        try tasks.complete(taskID: call.id, day: tasks.today)
        try tasks.complete(taskID: gym.id, day: tasks.today)
        let free = try content(at: 13)
        #expect(free == .free(allDoneCount: 2))
        #expect(DeepLink(url: free.url) == .today())
        // A missed task means not all were done (D-091).
        try make("Missed", .part(.morning))
        #expect(try content(at: 13) == .free(allDoneCount: nil))
    }

    @Test func hideTaskNamesMarksTitlesPrivate() async throws {
        try make("Interview", .fixed(minute: 750))
        #expect(try item(at: 11, 45)?.hidesTitle == false)
        let settings = SettingsManager(store: store, refresh: RefreshManager(widgets: widgets))
        var value = try settings.loadOrCreate()
        value.hideLockScreenTitles = true
        let reloads = widgets.count
        try settings.update(value)
        #expect(await eventually { widgets.count > reloads })
        #expect(try item(at: 11, 45)?.hidesTitle == true)
    }

    @Test func changesOnItsOwnAsTimePasses() throws {
        try make("Interview", .fixed(minute: 750))
        try make("Gym", .part(.evening))
        // The timeline has entries an hour before the fixed time and at each part start.
        let plan = WidgetTimelinePlan.make(now: TestEnvironment.date(2026, 10, 6, 9)) {
            try SnapshotLoader.load(store: store, deviceState: TestEnvironment.deviceState(), clock: clock)
        }
        #expect(plan.moments.contains(TestEnvironment.date(2026, 10, 6, 11, 30)))
        #expect(plan.moments.contains(TestEnvironment.date(2026, 10, 6, 17)))
        #expect(try item(at: 11, 30)?.inline == "Next: Interview at \(time(750))")
        #expect(try item(at: 17)?.topLine == "Evening · until \(time(1260))")
    }
}
