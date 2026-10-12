import Core
import Foundation
import Testing

@testable import Tempo

/// SPEC T-43: Snooze on fixed-time and ending-soon reminders, without opening the app.
@MainActor
struct SnoozeTests {
    private let clock = TestEnvironment.clock(hour: 9)
    private let scheduler = FixedNotificationScheduler(permission: .allowed)
    private let deviceState = TestEnvironment.deviceState()
    private let dependencies: AppDependencies

    init() throws {
        dependencies = AppDependencies(
            clock: clock, store: try TestEnvironment.store(clock: clock), deviceState: deviceState,
            notifications: scheduler, widgets: WidgetReloadCounter())
        dependencies.prepare()
    }

    private func pending(_ id: String) -> ScheduledNotification? {
        scheduler.pending.first { $0.id == id }
    }

    /// A Snooze tap as the notification delivers it.
    private func tap(_ action: String, on notification: ScheduledNotification) throws -> SnoozeRequest {
        let target = try #require(notification.snooze)
        return try #require(SnoozeRequest(actionIdentifier: action, userInfo: SnoozeRequest.userInfo(for: target)))
    }

    @Test func remindersCarryTheSnoozeButtonsThatFit() async throws {
        try dependencies.tasks.createOneTime(
            title: "Interview", date: TestEnvironment.today, timing: .fixed(minute: 750))
        try dependencies.tasks.createOneTime(title: "Gym", date: TestEnvironment.today, timing: .part(.evening))
        await dependencies.reminders.rebuild()
        let fixed = try #require(scheduler.pending.first { $0.id.hasPrefix("fixed.") })
        #expect(fixed.categoryIdentifier == NotificationCategory.snoozeBoth)
        #expect(pending("ending-soon.20261006.evening")?.categoryIdentifier == NotificationCategory.snoozeQuarter)
        #expect(pending("recap.20261006")?.categoryIdentifier == nil)
    }

    @Test func snoozingSchedulesOneReminderAndSnoozingAgainReplacesIt() async throws {
        let interview = try dependencies.tasks.createOneTime(
            title: "Interview", date: TestEnvironment.today, timing: .fixed(minute: 750))
        let fixedID = "fixed.\(interview.id.uuidString.lowercased()).20261006"
        // The reminder fired at 12:20; it's snoozed for 15 minutes at 12:21.
        clock.now = TestEnvironment.date(2026, 10, 6, 12, 21)
        let reminder = ScheduledNotification(
            id: fixedID, fireDate: TestEnvironment.date(2026, 10, 6, 12, 20), title: "", body: "",
            url: DeepLink.today().url, categoryIdentifier: NotificationCategory.snoozeBoth,
            snooze: SnoozeTarget(
                originalID: fixedID, kind: .fixed, day: TestEnvironment.today,
                partEnd: TestEnvironment.date(2026, 10, 6, 17, 0), options: [.fifteenMinutes, .oneHour]))
        await dependencies.reminders.snooze(try tap(NotificationCategory.snooze15, on: reminder))
        let snoozed = try #require(pending("snooze." + fixedID))
        #expect(snoozed.fireDate == TestEnvironment.date(2026, 10, 6, 12, 36))
        #expect(snoozed.title == "Interview at \(TimeOfDayFormatter.string(minute: 750))")
        #expect(snoozed.body == "Started 6 min ago")
        #expect(snoozed.categoryIdentifier == NotificationCategory.snoozeBoth)

        // Snoozing the snoozed reminder replaces it.
        clock.now = TestEnvironment.date(2026, 10, 6, 12, 37)
        await dependencies.reminders.snooze(try tap(NotificationCategory.snooze60, on: snoozed))
        #expect(scheduler.pending.filter { $0.id.hasPrefix("snooze.") }.count == 1)
        #expect(pending("snooze." + fixedID)?.fireDate == TestEnvironment.date(2026, 10, 6, 13, 37))
        #expect(deviceState.snoozes?.snoozes.count == 1)
    }

    @Test func completingTheTaskCancelsTheSnooze() async throws {
        let interview = try dependencies.tasks.createOneTime(
            title: "Interview", date: TestEnvironment.today, timing: .fixed(minute: 750))
        clock.now = TestEnvironment.date(2026, 10, 6, 12, 21)
        let fixedID = "fixed.\(interview.id.uuidString.lowercased()).20261006"
        let target = SnoozeTarget(
            originalID: fixedID, kind: .fixed, day: TestEnvironment.today,
            partEnd: TestEnvironment.date(2026, 10, 6, 17, 0), options: [.fifteenMinutes])
        let request = try #require(
            SnoozeRequest(
                actionIdentifier: NotificationCategory.snooze15, userInfo: SnoozeRequest.userInfo(for: target)))
        await dependencies.reminders.snooze(request)
        #expect(pending("snooze." + fixedID) != nil)
        try dependencies.tasks.complete(taskID: interview.id, day: TestEnvironment.today)
        await dependencies.reminders.rebuild()
        #expect(pending("snooze." + fixedID) == nil)
        #expect(deviceState.snoozes == nil)
    }

    @Test func aTapTooCloseToThePartsEndSchedulesNothing() async throws {
        try dependencies.tasks.createOneTime(title: "Gym", date: TestEnvironment.today, timing: .part(.evening))
        clock.now = TestEnvironment.date(2026, 10, 6, 20, 56)
        let target = SnoozeTarget(
            originalID: "ending-soon.20261006.evening", kind: .endingSoon, day: TestEnvironment.today,
            partEnd: TestEnvironment.date(2026, 10, 6, 21, 0), options: [.fifteenMinutes])
        let request = try #require(
            SnoozeRequest(
                actionIdentifier: NotificationCategory.snooze15, userInfo: SnoozeRequest.userInfo(for: target)))
        await dependencies.reminders.snooze(request)
        #expect(!scheduler.pending.contains { $0.id.hasPrefix("snooze.") })
        // Tapped at 20:50 it fires at 20:55, 5 minutes before Night.
        clock.now = TestEnvironment.date(2026, 10, 6, 20, 50)
        await dependencies.reminders.snooze(request)
        #expect(pending("snooze.ending-soon.20261006.evening")?.fireDate == TestEnvironment.date(2026, 10, 6, 20, 55))
        #expect(pending("snooze.ending-soon.20261006.evening")?.title == "Evening ends in 5 min")
    }

    @Test func snoozesClearWhenTheDayChanges() async throws {
        try dependencies.tasks.createOneTime(title: "Gym", date: TestEnvironment.today, timing: .part(.evening))
        deviceState.snoozes = SnoozeList(
            day: DayKey(year: 2026, month: 10, day: 5),
            snoozes: [
                Snooze(
                    originalID: "ending-soon.20261005.evening", kind: .endingSoon,
                    fireDate: TestEnvironment.date(2026, 10, 5, 20, 45), day: DayKey(year: 2026, month: 10, day: 5))
            ])
        await dependencies.reminders.rebuild()
        #expect(!scheduler.pending.contains { $0.id.hasPrefix("snooze.") })
        #expect(deviceState.snoozes == nil)
    }

    @Test func otherActionsAreNotSnoozes() {
        let userInfo = SnoozeRequest.userInfo(
            for: SnoozeTarget(
                originalID: "ending-soon.20261006.evening", kind: .endingSoon, day: TestEnvironment.today,
                partEnd: TestEnvironment.date(2026, 10, 6, 21, 0), options: [.fifteenMinutes]))
        #expect(SnoozeRequest(actionIdentifier: NotificationCategory.stop, userInfo: userInfo) == nil)
        #expect(SnoozeRequest(actionIdentifier: NotificationCategory.snooze15, userInfo: [:]) == nil)
    }

    @Test func withPermissionRefusedNothingIsScheduled() async throws {
        try dependencies.tasks.createOneTime(title: "Gym", date: TestEnvironment.today, timing: .part(.evening))
        scheduler.setPermission(.denied)
        clock.now = TestEnvironment.date(2026, 10, 6, 20, 31)
        let target = SnoozeTarget(
            originalID: "ending-soon.20261006.evening", kind: .endingSoon, day: TestEnvironment.today,
            partEnd: TestEnvironment.date(2026, 10, 6, 21, 0), options: [.fifteenMinutes])
        let request = try #require(
            SnoozeRequest(
                actionIdentifier: NotificationCategory.snooze15, userInfo: SnoozeRequest.userInfo(for: target)))
        await dependencies.reminders.snooze(request)
        #expect(scheduler.pending.isEmpty)
    }
}
