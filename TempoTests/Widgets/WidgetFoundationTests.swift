import Core
import Foundation
import Testing

@testable import Tempo

/// SPEC T-22: widgets read the app's data, change at the right moments, refresh after every change, and show a
/// fallback when they can't read.
@MainActor
struct WidgetFoundationTests {
    private let clock = TestEnvironment.clock(hour: 9)

    private struct LoadFailed: Error {}

    @Test func widgetsReadTheSameDataAsTheApp() throws {
        let url = try StoreFactory.storeURL(fileName: "Tempo-widgets-\(UUID().uuidString).store")
        defer {
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(at: URL(filePath: url.path() + suffix))
            }
        }
        let deviceState = TestEnvironment.deviceState()
        let appStore = SwiftDataTaskStore(container: try StoreFactory.make(url: url), clock: clock)
        let tasks = TaskManager(
            store: appStore, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()),
            deviceState: deviceState)
        let call = try tasks.createOneTime(title: "Call", date: tasks.today, timing: .part(.noon))
        try tasks.complete(taskID: call.id, day: tasks.today)
        try tasks.createOneTime(title: "Gym", date: tasks.today, timing: .part(.evening))

        // The extension opens its own container on the same file.
        let widgetStore = SwiftDataTaskStore(container: try StoreFactory.make(url: url), clock: clock)
        let snapshot = try SnapshotLoader.load(store: widgetStore, deviceState: deviceState, clock: clock)
        let widgetPlan = snapshot.plan(at: clock.now)
        let appPlan = DayPlan(day: tasks.today, snapshot: try tasks.snapshot(), now: clock.now)
        #expect(widgetPlan == appPlan)
        #expect(widgetPlan.items.map(\.task.title) == ["Call", "Gym"])
        #expect(widgetPlan.items.first?.status == .done)
    }

    /// SPEC T-37: the extension reads the settings columns added in version 4 of the store.
    @Test func widgetsReadTheNewSettingsColumns() throws {
        let url = try StoreFactory.storeURL(fileName: "Tempo-widgets-\(UUID().uuidString).store")
        defer {
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(at: URL(filePath: url.path() + suffix))
            }
        }
        let appStore = SwiftDataTaskStore(container: try StoreFactory.make(url: url), clock: clock)
        var settings = SettingsValue.defaults
        settings.missedStyle = .strict
        settings.partStartSummaries = [.morning, .evening]
        try appStore.save(settings)

        let widgetStore = SwiftDataTaskStore(container: try StoreFactory.make(url: url), clock: clock)
        let snapshot = try SnapshotLoader.load(
            store: widgetStore, deviceState: TestEnvironment.deviceState(), clock: clock)
        #expect(snapshot.core.settings.missedStyle == .strict)
        #expect(snapshot.core.settings.partStartSummaries == [.morning, .evening])
    }

    @Test func timelineChangesAtPartBoundariesFixedTimesAndMidnight() throws {
        let store = try TestEnvironment.store(clock: clock)
        let tasks = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
        try tasks.createOneTime(title: "Interview", date: tasks.today, timing: .fixed(minute: 750))
        let loaded = try SnapshotLoader.load(store: store, deviceState: TestEnvironment.deviceState(), clock: clock)
        let plan = WidgetTimelinePlan.make(now: clock.now) { loaded }
        #expect(plan.snapshot != nil)
        #expect(plan.moments.first == clock.now)
        for (hour, minute) in [(11, 30), (12, 0), (12, 30), (17, 0), (21, 0)] {
            #expect(plan.moments.contains(TestEnvironment.date(2026, 10, 6, hour, minute)), "\(hour):\(minute)")
        }
        #expect(plan.moments.contains(TestEnvironment.date(2026, 10, 7, 0, 0)))
        #expect(plan.refreshAfter == TestEnvironment.date(2026, 10, 7, 0, 0))
        // Each moment shows that moment's statuses.
        let snapshot = try #require(plan.snapshot)
        #expect(snapshot.plan(at: TestEnvironment.date(2026, 10, 6, 12, 0)).items.first?.status == Status.open)
        #expect(snapshot.plan(at: TestEnvironment.date(2026, 10, 6, 17, 0)).items.first?.status == Status.missed)
    }

    @Test func aHabitTimerAddsTheMomentItsTargetIsReached() throws {
        let store = try TestEnvironment.store(clock: clock)
        let deviceState = TestEnvironment.deviceState()
        let refresh = RefreshManager(widgets: WidgetReloadCounter())
        let tasks = TaskManager(store: store, clock: clock, refresh: refresh, deviceState: deviceState)
        let read = try tasks.createHabit(
            type: .duration, title: "Read", timing: .anytime, weekdays: .all, startDay: tasks.today, lengthDays: nil,
            targetMinutes: 30)
        try tasks.logTime(taskID: read.id, minutes: 10)
        try TimerManager(deviceState: deviceState, tasks: tasks, clock: clock, refresh: refresh).startHabitTimer(
            taskID: read.id)
        let loaded = try SnapshotLoader.load(store: store, deviceState: deviceState, clock: clock)
        let plan = WidgetTimelinePlan.make(now: clock.now) { loaded }
        #expect(plan.snapshot?.timerHabitTitle == "Read")
        #expect(plan.moments.contains(clock.now.addingTimeInterval(20 * 60)))
    }

    @Test func aLoadFailureShowsTheFallbackAndRetriesIn15Minutes() {
        let plan = WidgetTimelinePlan.make(now: clock.now) { throw LoadFailed() }
        #expect(plan.snapshot == nil)
        #expect(plan.moments == [clock.now])
        #expect(plan.refreshAfter == clock.now.addingTimeInterval(15 * 60))
    }

    @Test func aWidgetButtonRefreshesEveryWidgetAndRebuildsNotifications() async throws {
        let store = try TestEnvironment.store(clock: clock)
        try store.save(SettingsValue.defaults)
        let widgets = WidgetReloadCounter()
        let scheduler = FixedNotificationScheduler(permission: .allowed)
        let environment = IntentEnvironment.make(
            store: store, deviceState: TestEnvironment.deviceState(), clock: clock, widgets: widgets,
            scheduler: scheduler)
        let call = try environment.tasks.createOneTime(
            title: "Call", date: environment.tasks.today, timing: .part(.noon))
        let replacementsBefore = scheduler.replaceCount

        let intent = ToggleCompletionIntent(taskID: call.id, day: environment.tasks.today, done: true)
        intent.value = true
        try await intent.run(in: environment)
        #expect(try store.completions(taskID: call.id).count == 1)
        #expect(widgets.count >= 1)
        #expect(scheduler.replaceCount > replacementsBefore)
        #expect(!scheduler.pending.contains { $0.id == "part-start.20261006.noon" })

        intent.value = false
        try await intent.run(in: environment)
        #expect(try store.completions(taskID: call.id).isEmpty)
        #expect(scheduler.pending.contains { $0.id == "part-start.20261006.noon" })
    }
}
