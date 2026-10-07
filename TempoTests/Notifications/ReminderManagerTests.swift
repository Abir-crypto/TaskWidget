import Core
import Foundation
import Testing

@testable import Tempo

@MainActor
struct ReminderManagerTests {
    private let clock = TestEnvironment.clock(hour: 9)
    private let scheduler = FixedNotificationScheduler(permission: .allowed)
    private let dependencies: AppDependencies

    init() throws {
        dependencies = AppDependencies(
            clock: clock, store: try TestEnvironment.store(clock: clock), deviceState: TestEnvironment.deviceState(),
            notifications: scheduler, widgets: WidgetReloadCounter())
        dependencies.prepare()
    }

    private var ids: [String] { scheduler.pending.map(\.id) }

    @Test func rebuildSchedulesThePlan() async throws {
        let call = try dependencies.tasks.createOneTime(
            title: "Call the bank", date: TestEnvironment.today, timing: .fixed(minute: 750))
        await dependencies.reminders.rebuild()
        #expect(ids.contains("part-start.20261006.noon"))
        #expect(ids.contains("ending-soon.20261006.noon"))
        #expect(ids.contains("fixed.\(call.id.uuidString.lowercased()).20261006"))
        #expect(ids.contains("recap.20261006"))
        let fixed = try #require(scheduler.pending.first { $0.id.hasPrefix("fixed.") })
        #expect(fixed.fireDate == TestEnvironment.date(2026, 10, 6, 12, 20))
        #expect(fixed.body == "In 10 min")
        #expect(DeepLink(url: fixed.url) == .today(day: TestEnvironment.today, taskID: call.id))
        #expect(scheduler.pending.count <= 60)
    }

    @Test func refusedPermissionSchedulesNothing() async throws {
        scheduler.setPermission(.denied)
        try dependencies.tasks.createOneTime(title: "Call", date: TestEnvironment.today, timing: .part(.noon))
        await dependencies.reminders.rebuild()
        #expect(scheduler.pending.isEmpty)
        scheduler.setPermission(.notDetermined)
        await dependencies.reminders.rebuild()
        #expect(scheduler.pending.isEmpty)
    }

    @Test func completingATaskUpdatesWhatsWaiting() async throws {
        let call = try dependencies.tasks.createOneTime(
            title: "Call", date: TestEnvironment.today, timing: .part(.noon))
        try dependencies.tasks.createOneTime(title: "Pay", date: TestEnvironment.today, timing: .part(.noon))
        await dependencies.reminders.rebuild()
        #expect(scheduler.pending.first { $0.id == "part-start.20261006.noon" }?.title == "Noon · 2 tasks")
        try dependencies.tasks.complete(taskID: call.id, day: TestEnvironment.today)
        await dependencies.reminders.rebuild()
        #expect(scheduler.pending.first { $0.id == "part-start.20261006.noon" }?.body == "Pay")
    }

    @Test func turningAKindOffOrChangingALeadTakesEffect() async throws {
        try dependencies.tasks.createOneTime(
            title: "Interview", date: TestEnvironment.today, timing: .fixed(minute: 750))
        var settings = try dependencies.settings.loadOrCreate()
        settings.notifyFixed = false
        settings.endingSoonLead = 60
        try dependencies.settings.update(settings)
        await dependencies.reminders.rebuild()
        #expect(!ids.contains { $0.hasPrefix("fixed.") })
        #expect(
            scheduler.pending.first { $0.id == "ending-soon.20261006.noon" }?.fireDate
                == TestEnvironment.date(2026, 10, 6, 16))
    }

    @Test func runningTimerGetsItsAlertWithActions() async throws {
        let read = try dependencies.tasks.createHabit(
            type: .duration, title: "Read", timing: .anytime, weekdays: .all, startDay: TestEnvironment.today,
            lengthDays: nil, targetMinutes: 30)
        try dependencies.timer.startHabitTimer(taskID: read.id)
        await dependencies.reminders.rebuild()
        let alert = try #require(scheduler.pending.first { $0.id == "timer-alert" })
        #expect(alert.title == "Read timer is still running")
        #expect(alert.categoryIdentifier == "TIMER_ALERT")
        #expect(DeepLink(url: alert.url) == .timer)
        dependencies.timer.pause()
        await dependencies.reminders.rebuild()
        #expect(!ids.contains("timer-alert"))
    }

    @Test func everyChangeRebuildsThroughTheRefresh() async throws {
        try dependencies.tasks.createOneTime(title: "Call", date: TestEnvironment.today, timing: .part(.noon))
        #expect(await eventually { scheduler.pending.contains { $0.id == "part-start.20261006.noon" } })
    }

    @Test func overlappingRebuildsEndOnTheLatestData() async throws {
        async let first: Void = dependencies.reminders.rebuild()
        async let second: Void = dependencies.reminders.rebuild()
        _ = await (first, second)
        try dependencies.tasks.createOneTime(title: "Call", date: TestEnvironment.today, timing: .part(.noon))
        await dependencies.reminders.rebuild()
        #expect(ids.contains("part-start.20261006.noon"))
    }
}
