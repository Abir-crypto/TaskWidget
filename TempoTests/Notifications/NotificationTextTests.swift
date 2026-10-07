import Core
import Foundation
import Testing

@testable import Tempo

/// The F-07 examples, word for word.
struct NotificationTextTests {
    private let day = TestEnvironment.today

    private func item(_ title: String, fixed: Int? = nil, minutes: Int? = nil, target: Int? = nil) -> ReminderItem {
        ReminderItem(taskID: UUID(), title: title, fixedMinute: fixed, minutes: minutes, targetMinutes: target)
    }

    private var time1230: String { TimeOfDayFormatter.string(minute: 750) }

    @Test func partStarts() {
        let content = ReminderContent.partStart(
            day: day, part: .noon,
            items: [item("Call the bank"), item("Interview", fixed: 750), item("Read", minutes: 0, target: 30)],
            anytime: [])
        #expect(NotificationText.title(for: content) == "Noon · 3 tasks")
        #expect(NotificationText.body(for: content) == "Call the bank, Interview at \(time1230), Read")
    }

    @Test func morningListsAnytimeTasksToo() {
        let content = ReminderContent.partStart(
            day: day, part: .morning, items: [item("Stretch")], anytime: [item("Renew passport"), item("Call mum")])
        #expect(NotificationText.title(for: content) == "Morning · 3 tasks")
        #expect(NotificationText.body(for: content) == "Stretch …and 2 anytime")
        let onlyAnytime = ReminderContent.partStart(
            day: day, part: .morning, items: [], anytime: [item("Renew passport")])
        #expect(NotificationText.title(for: onlyAnytime) == "Morning · 1 task")
        #expect(NotificationText.body(for: onlyAnytime) == "Renew passport")
    }

    @Test func endingSoon() {
        let content = ReminderContent.endingSoon(
            day: day, part: .evening, minutesLeft: 30, items: [item("Gym"), item("Read", minutes: 10, target: 30)])
        #expect(NotificationText.title(for: content) == "Evening ends in 30 min")
        #expect(NotificationText.body(for: content) == "2 left: Gym, Read (10 of 30 min)")
    }

    @Test func fixedTime() {
        let content = ReminderContent.fixed(day: day, item: item("Interview", fixed: 750), leadMinutes: 10)
        #expect(NotificationText.title(for: content) == "Interview at \(time1230)")
        #expect(NotificationText.body(for: content) == "In 10 min")
    }

    @Test func recap() {
        let content = ReminderContent.recap(
            day: day, missed: [item("Call the bank"), item("Read", minutes: 20, target: 30)],
            open: [item("Plan tomorrow")])
        #expect(NotificationText.title(for: content) == "Today: 2 missed, 1 still open")
        #expect(NotificationText.body(for: content) == "Call the bank, Read (20 of 30 min), Plan tomorrow")
        #expect(NotificationText.title(for: .recap(day: day, missed: [item("A")], open: [])) == "Today: 1 missed")
        #expect(NotificationText.title(for: .recap(day: day, missed: [], open: [item("A")])) == "Today: 1 still open")
    }

    @Test func timerAlert() {
        let habit = ReminderContent.timerAlert(habitTitle: "Read", runningMinutes: 120)
        #expect(NotificationText.title(for: habit) == "Read timer is still running")
        #expect(NotificationText.body(for: habit) == "It's been running for 2 hours.")
        let generic = ReminderContent.timerAlert(habitTitle: nil, runningMinutes: 60)
        #expect(NotificationText.title(for: generic) == "Timer is still running")
        #expect(NotificationText.body(for: generic) == "It's been running for 1 hour.")
    }

    @Test func listsShowThreeNamesThenAndMore() {
        #expect(NotificationText.list(["A", "B", "C"]) == "A, B, C")
        #expect(NotificationText.list(["A", "B", "C", "D", "E"]) == "A, B, C and 2 more")
    }

    @Test func linksOpenTheRightPlace() {
        let taskID = UUID()
        #expect(
            DeepLink(url: NotificationText.url(for: .today(day: day, part: .noon, taskID: nil)))
                == .today(day: day, part: .noon))
        #expect(
            DeepLink(url: NotificationText.url(for: .today(day: day, part: nil, taskID: taskID)))
                == .today(day: day, taskID: taskID))
        #expect(DeepLink(url: NotificationText.url(for: .missed)) == .missed)
        #expect(DeepLink(url: NotificationText.url(for: .timer)) == .timer)
    }
}
