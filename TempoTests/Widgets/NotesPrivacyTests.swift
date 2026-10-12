import Core
import Foundation
import Testing

@testable import Tempo

/// SPEC F-01 (T-38): notes never appear in widgets, on the Lock Screen or in notifications.
@MainActor
struct NotesPrivacyTests {
    private let clock = TestEnvironment.clock(hour: 9)
    private let store: SwiftDataTaskStore
    private let tasks: TaskManager
    private let secret = "Account number 1234"

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        try store.save(SettingsValue.defaults)
        tasks = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
        try tasks.createOneTime(title: "Call the bank", notes: secret, date: tasks.today, timing: .fixed(minute: 600))
        try tasks.createHabit(
            type: .duration, title: "Read", notes: secret, timing: .part(.evening), weekdays: .all,
            startDay: tasks.today, lengthDays: nil, targetMinutes: 30)
    }

    private func snapshot() throws -> WidgetSnapshot {
        try SnapshotLoader.load(store: store, deviceState: TestEnvironment.deviceState(), clock: clock)
    }

    @Test func focusAndLockScreenWidgetsShowOnlyTitles() throws {
        let snapshot = try snapshot()
        for hour in [9, 10, 18] {
            let date = TestEnvironment.date(2026, 10, 6, hour)
            let focus = String(describing: FocusWidgetContent(snapshot: snapshot, at: date))
            let lockScreen = String(describing: LockScreenWidgetContent(snapshot: snapshot, at: date))
            #expect(focus.contains("Call the bank") || focus.contains("Read"))
            #expect(!focus.contains(secret))
            #expect(!lockScreen.contains(secret))
        }
    }

    @Test func notificationsShowOnlyTitles() throws {
        let plan = ReminderPlanner.plan(snapshot: try tasks.snapshot(), now: clock.now)
        #expect(!plan.isEmpty)
        for notification in plan {
            let text =
                NotificationText.title(for: notification.content, missedStyle: .gentle)
                + NotificationText.body(for: notification.content)
            #expect(!text.contains(secret))
        }
    }
}
