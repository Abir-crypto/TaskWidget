import Foundation
import Testing

@testable import Core

struct ReminderPlannerTests {
    /// Every part's summary switched on, so these tests see each kind; the defaults are checked on their own.
    private static let everySummary: SettingsValue = {
        var settings = SettingsValue.defaults
        settings.partStartSummaries = Set(DayPart.allCases)
        return settings
    }()

    private func plan(
        _ fixtures: Fixtures, at now: Date, settings: SettingsValue = Self.everySummary,
        timer: ReminderPlanner.RunningTimer? = nil,
        limit: Int = ReminderPlanner.defaultLimit
    ) -> [PlannedNotification] {
        ReminderPlanner.plan(snapshot: fixtures.snapshot(settings: settings), now: now, timer: timer, limit: limit)
    }

    private func today(_ plan: [PlannedNotification]) -> [PlannedNotification] {
        plan.filter { $0.id.contains("20261006") || $0.id == "timer-alert" }
    }

    @Test func partStartFiresAtThePartsStartWhenItHasTasks() throws {
        var fixtures = Fixtures()
        let call = fixtures.oneTime("Call the bank", timing: .part(.noon))
        let interview = fixtures.oneTime("Interview", timing: .fixed(minute: 750))
        let notifications = plan(fixtures, at: TestCalendar.today(9))
        let noon = try #require(notifications.first { $0.id == "part-start.20261006.noon" })
        #expect(noon.fireDate == TestCalendar.today(12))
        guard case .partStart(_, let part, let items, let anytime) = noon.content else {
            Issue.record("Wrong content")
            return
        }
        #expect(part == .noon)
        #expect(items.map(\.taskID) == [interview.id, call.id])
        #expect(anytime.isEmpty)
        #expect(noon.content.destination == .today(day: TestCalendar.today, part: .noon, taskID: nil))
        // Parts with nothing to do get no summary.
        #expect(!notifications.contains { $0.id == "part-start.20261006.evening" })
    }

    @Test func morningSummaryIncludesAnytimeTasksEvenWithoutMorningTasks() throws {
        var fixtures = Fixtures()
        let passport = fixtures.oneTime("Renew passport", on: TestCalendar.oct(7), timing: .anytime)
        let morning = try #require(
            plan(fixtures, at: TestCalendar.today(9)).first { $0.id == "part-start.20261007.morning" })
        guard case .partStart(_, _, let items, let anytime) = morning.content else {
            Issue.record("Wrong content")
            return
        }
        #expect(items.isEmpty)
        #expect(anytime.map(\.taskID) == [passport.id])
    }

    @Test func endingSoonFiresTheLeadBeforeThePartEnds() throws {
        var fixtures = Fixtures()
        fixtures.oneTime("Gym", timing: .part(.evening))
        let read = fixtures.duration("Read", timing: .part(.evening), target: 30)
        fixtures.log(read, minutes: 10, on: TestCalendar.today)
        let ending = try #require(
            plan(fixtures, at: TestCalendar.today(9)).first { $0.id == "ending-soon.20261006.evening" })
        #expect(ending.fireDate == TestCalendar.today(20, 30))
        guard case .endingSoon(_, _, let minutesLeft, let items) = ending.content else {
            Issue.record("Wrong content")
            return
        }
        #expect(minutesLeft == 30)
        #expect(items.last?.minutes == 10)
        #expect(items.last?.targetMinutes == 30)
    }

    @Test func endingSoonIsNeverBeforeThePartStarts() throws {
        var fixtures = Fixtures()
        fixtures.oneTime("Quick", timing: .part(.noon))
        var settings = SettingsValue.defaults
        settings.parts = settings.parts.setting(.evening, to: 750)  // Noon lasts 30 minutes
        settings.endingSoonLead = 60
        let ending = try #require(
            plan(fixtures, at: TestCalendar.today(9), settings: settings).first { $0.id == "ending-soon.20261006.noon" }
        )
        #expect(ending.fireDate == TestCalendar.today(12))
        guard case .endingSoon(_, _, let minutesLeft, _) = ending.content else {
            Issue.record("Wrong content")
            return
        }
        #expect(minutesLeft == 30)
    }

    @Test func fixedTimeReminderAndTheLeadInThePast() throws {
        var fixtures = Fixtures()
        let interview = fixtures.oneTime("Interview", timing: .fixed(minute: 750))
        let reminder = try #require(plan(fixtures, at: TestCalendar.today(9)).first { $0.id.hasPrefix("fixed.") })
        #expect(reminder.id == "fixed.\(interview.id.uuidString.lowercased()).20261006")
        #expect(reminder.fireDate == TestCalendar.today(12, 20))
        #expect(reminder.content.destination == .today(day: TestCalendar.today, part: nil, taskID: interview.id))
        // Created at 12:25 for 12:30: the reminder would be in the past, so none is sent.
        #expect(!plan(fixtures, at: TestCalendar.today(12, 25)).contains { $0.id.hasPrefix("fixed.") })
    }

    @Test func recapCountsMissedAndStillOpenAtTheRecapTime() throws {
        var fixtures = Fixtures()
        fixtures.oneTime("Call the bank", timing: .part(.noon))
        let read = fixtures.duration("Read", timing: .part(.evening), target: 30)
        fixtures.log(read, minutes: 20, on: TestCalendar.today)
        fixtures.oneTime("Plan tomorrow", timing: .part(.night))
        let done = fixtures.oneTime("Done", timing: .anytime)
        fixtures.complete(done, on: TestCalendar.today)
        let recap = try #require(plan(fixtures, at: TestCalendar.today(9)).first { $0.id == "recap.20261006" })
        #expect(recap.fireDate == TestCalendar.today(23, 30))
        guard case .recap(_, let missed, let open) = recap.content else {
            Issue.record("Wrong content")
            return
        }
        #expect(missed.map(\.title) == ["Call the bank", "Read"])
        #expect(open.map(\.title) == ["Plan tomorrow"])
        #expect(recap.content.destination == .missed)
    }

    @Test func completingATaskRemovesItOrCancelsTheNotification() throws {
        var fixtures = Fixtures()
        let call = fixtures.oneTime("Call", timing: .part(.noon))
        let other = fixtures.oneTime("Other", timing: .part(.noon))
        fixtures.complete(call, on: TestCalendar.today)
        let noon = try #require(plan(fixtures, at: TestCalendar.today(9)).first { $0.id == "part-start.20261006.noon" })
        guard case .partStart(_, _, let items, _) = noon.content else {
            Issue.record("Wrong content")
            return
        }
        #expect(items.map(\.taskID) == [other.id])
        fixtures.complete(other, on: TestCalendar.today)
        let ids = today(plan(fixtures, at: TestCalendar.today(9))).map(\.id)
        #expect(!ids.contains("part-start.20261006.noon"))
        #expect(!ids.contains("ending-soon.20261006.noon"))
        #expect(!ids.contains("recap.20261006"))
    }

    @Test func durationHabitCountsUntilItReachesItsTarget() {
        var fixtures = Fixtures()
        let read = fixtures.duration("Read", timing: .part(.evening), target: 30)
        fixtures.log(read, minutes: 29, on: TestCalendar.today)
        #expect(today(plan(fixtures, at: TestCalendar.today(9))).contains { $0.id == "ending-soon.20261006.evening" })
        fixtures.log(read, minutes: 1, on: TestCalendar.today)
        #expect(!today(plan(fixtures, at: TestCalendar.today(9))).contains { $0.id == "ending-soon.20261006.evening" })
    }

    @Test func eachKindCanBeTurnedOff() {
        var fixtures = Fixtures()
        fixtures.oneTime("Interview", timing: .fixed(minute: 750))
        var settings = Self.everySummary
        settings.partStartSummaries = []
        settings.notifyEndingSoon = false
        settings.notifyFixed = false
        settings.notifyRecap = false
        #expect(plan(fixtures, at: TestCalendar.today(9), settings: settings).isEmpty)
    }

    @Test func leadTimesFollowTheSettings() throws {
        var fixtures = Fixtures()
        fixtures.oneTime("Interview", timing: .fixed(minute: 750))
        var settings = SettingsValue.defaults
        settings.fixedLead = 30
        settings.endingSoonLead = 15
        settings.recapMinute = 1320
        let notifications = plan(fixtures, at: TestCalendar.today(9), settings: settings)
        #expect(notifications.first { $0.id.hasPrefix("fixed.") }?.fireDate == TestCalendar.today(12))
        #expect(notifications.first { $0.id == "ending-soon.20261006.noon" }?.fireDate == TestCalendar.today(16, 45))
        #expect(notifications.first { $0.id == "recap.20261006" }?.fireDate == TestCalendar.today(22))
    }

    @Test func plansAtLeast48HoursAheadEarliestFirstWithinTheLimit() {
        var fixtures = Fixtures()
        fixtures.habit("Daily", timing: .part(.morning), start: TestCalendar.today)
        let notifications = plan(fixtures, at: TestCalendar.today(9))
        #expect(notifications == notifications.sorted { $0.fireDate < $1.fireDate })
        #expect(notifications.allSatisfy { $0.fireDate > TestCalendar.today(9) })
        let last = notifications.last?.fireDate ?? .distantPast
        #expect(last >= TestCalendar.today(9).addingTimeInterval(48 * 3_600))
        #expect(last <= TestCalendar.today(9).addingTimeInterval(72 * 3_600))
        let trimmed = plan(fixtures, at: TestCalendar.today(9), limit: 4)
        #expect(trimmed == Array(notifications.prefix(4)))
    }

    @Test func timerAlertIsTheNextOneWhileRunning() throws {
        let start = TestCalendar.today(10)
        let running = TimerRules.start(kind: .habit, habitID: UUID(), now: start, calendar: TestCalendar.london)
        let notifications = plan(
            Fixtures(), at: start.addingTimeInterval(60),
            timer: ReminderPlanner.RunningTimer(state: running, habitTitle: "Read"))
        let alert = try #require(notifications.first { $0.id == "timer-alert" })
        #expect(alert.fireDate == start.addingTimeInterval(7_200))
        #expect(alert.content == .timerAlert(habitTitle: "Read", runningMinutes: 120))
        #expect(alert.content.destination == .timer)
        // After "Keep going", the next one comes a period later.
        let later = plan(
            Fixtures(), at: start.addingTimeInterval(7_300),
            timer: ReminderPlanner.RunningTimer(state: running, habitTitle: "Read"))
        #expect(later.first { $0.id == "timer-alert" }?.content == .timerAlert(habitTitle: "Read", runningMinutes: 240))
        // Paused: none.
        let paused = TimerRules.pause(running, now: start.addingTimeInterval(600))
        #expect(
            !plan(
                Fixtures(), at: start.addingTimeInterval(700),
                timer: ReminderPlanner.RunningTimer(state: paused, habitTitle: nil)
            )
            .contains { $0.id == "timer-alert" })
        var off = SettingsValue.defaults
        off.notifyTimer = false
        #expect(
            plan(
                Fixtures(), at: start, settings: off,
                timer: ReminderPlanner.RunningTimer(state: running, habitTitle: nil)
            ).isEmpty)
    }

    @Test func pastFireTimesAreDropped() {
        var fixtures = Fixtures()
        fixtures.oneTime("Morning", timing: .part(.morning))
        let ids = plan(fixtures, at: TestCalendar.today(13)).map(\.id)
        #expect(!ids.contains("part-start.20261006.morning"))
        #expect(!ids.contains("ending-soon.20261006.morning"))
        #expect(ids.contains("recap.20261006"))  // still ahead, and the task is missed
    }

    // MARK: A switch per part (SPEC F-07, F-16, D-109, T-42)

    @Test func onlyMorningsSummaryIsPlannedByDefault() {
        var fixtures = Fixtures()
        fixtures.oneTime("Stretch", timing: .part(.morning))
        fixtures.oneTime("Call", timing: .part(.noon))
        fixtures.oneTime("Gym", timing: .part(.evening))
        fixtures.oneTime("Read", timing: .part(.night))
        fixtures.oneTime("Passport", timing: .anytime)
        let ids = plan(fixtures, at: TestCalendar.today(5), settings: .defaults).map(\.id)
        #expect(ids.contains("part-start.20261006.morning"))
        #expect(!ids.contains { $0.hasPrefix("part-start.20261006.noon") })
        #expect(!ids.contains { $0.hasPrefix("part-start.20261006.evening") })
        #expect(!ids.contains { $0.hasPrefix("part-start.20261006.night") })
        // Ending-soon, fixed-time and recap reminders are unchanged.
        #expect(ids.contains("ending-soon.20261006.noon"))
        #expect(ids.contains("ending-soon.20261006.evening"))
        #expect(ids.contains("recap.20261006"))
    }

    @Test func morningsSummaryStillListsAnytimeTasks() throws {
        var fixtures = Fixtures()
        fixtures.oneTime("Passport", timing: .anytime)
        let morning = try #require(
            plan(fixtures, at: TestCalendar.today(5), settings: .defaults).first {
                $0.id == "part-start.20261006.morning"
            })
        guard case .partStart(_, _, let items, let anytime) = morning.content else {
            Issue.record("Not a part summary")
            return
        }
        #expect(items.isEmpty)
        #expect(anytime.map(\.title) == ["Passport"])
    }

    @Test func eachPartsSwitchPlansOnlyThatPart() {
        var fixtures = Fixtures()
        fixtures.oneTime("Stretch", timing: .part(.morning))
        fixtures.oneTime("Gym", timing: .part(.evening))
        var settings = SettingsValue.defaults
        settings.partStartSummaries = [.evening]
        let ids = plan(fixtures, at: TestCalendar.today(5), settings: settings).map(\.id)
        #expect(ids.contains("part-start.20261006.evening"))
        #expect(!ids.contains("part-start.20261006.morning"))
    }
}
