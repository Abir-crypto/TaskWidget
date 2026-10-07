import Core
import Foundation
import Testing

@testable import Tempo

@MainActor
struct TasksViewModelTests {
    private let clock = TestEnvironment.clock(hour: 9)
    private let store: SwiftDataTaskStore
    private let tasks: TaskManager
    private let model: TasksViewModel

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        tasks = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
        model = TasksViewModel(tasks: tasks, clock: clock)
    }

    private func day(_ day: Int) -> DayKey { DayKey(year: 2026, month: 10, day: day) }

    private func habit(
        _ title: String, type: TaskType = .progress, weekdays: Weekdays = .all, start: DayKey, length: Int? = nil,
        timing: Timing = .part(.evening)
    ) throws -> TaskValue {
        try tasks.createHabit(
            type: type, title: title, timing: timing, weekdays: weekdays, startDay: start, lengthDays: length,
            targetMinutes: type == .duration ? 30 : nil)
    }

    @Test func habitsShowActiveOnesWithTheirProgress() throws {
        clock.now = TestEnvironment.date(2026, 10, 5, 9)  // Monday
        let gym = try habit("Gym", weekdays: [.monday, .wednesday, .friday], start: day(5))
        try tasks.complete(taskID: gym.id, day: day(5))
        let read = try habit("Read", type: .duration, start: day(5))
        try tasks.logTime(taskID: read.id, minutes: 40)
        let ended = try habit("Old", start: day(5))
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        try tasks.endHabit(taskID: ended.id)
        let future = try habit("Later", start: day(10))
        model.load()

        #expect(model.habits.map(\.task.id) == [gym.id, read.id, future.id])
        let gymSummary = try #require(model.habits.first)
        #expect(gymSummary.progress == "1 of 3 this week")
        #expect(gymSummary.schedule.hasSuffix("· Evening"))
        #expect(model.habits[1].progress.hasSuffix("this week"))
        #expect(model.habits[1].progress.contains("40"))
        #expect(model.habits[1].schedule.hasPrefix("Every day"))
        #expect(model.habits[2].progress.hasPrefix("Starts"))
    }

    @Test func setLengthShowsTheDay() throws {
        clock.now = TestEnvironment.date(2026, 9, 25, 9)
        let medicine = try habit("Medicine", start: DayKey(year: 2026, month: 9, day: 25), length: 30)
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        model.load()
        #expect(model.habits.first { $0.task.id == medicine.id }?.progress == "Day 12 of 30")
    }

    @Test func oneTimeListsUpcomingTasksByDate() throws {
        let today = try tasks.createOneTime(title: "Today", date: day(6), timing: .part(.noon))
        let tomorrow = try tasks.createOneTime(title: "Tomorrow", date: day(7), timing: .anytime)
        let thursdayLate = try tasks.createOneTime(title: "Thursday night", date: day(8), timing: .part(.night))
        let thursdayEarly = try tasks.createOneTime(title: "Thursday 09:00", date: day(8), timing: .fixed(minute: 540))
        let done = try tasks.createOneTime(title: "Done", date: day(6), timing: .anytime)
        try tasks.complete(taskID: done.id, day: day(6))
        let missed = try tasks.createOneTime(title: "Missed", date: day(6), timing: .part(.morning))
        clock.now = TestEnvironment.date(2026, 10, 6, 13)
        model.load()

        #expect(model.oneTimeGroups.map(\.day) == [day(6), day(7), day(8)])
        #expect(model.oneTimeGroups.map(\.title).prefix(2) == ["Today", "Tomorrow"])
        #expect(model.oneTimeGroups[0].items.map(\.task.id) == [today.id])
        #expect(model.oneTimeGroups[1].items.map(\.task.id) == [tomorrow.id])
        #expect(model.oneTimeGroups[2].items.map(\.task.id) == [thursdayEarly.id, thursdayLate.id])
        let listed = Set(model.oneTimeGroups.flatMap(\.items).map(\.task.id))
        #expect(!listed.contains(done.id))
        #expect(!listed.contains(missed.id))
    }

    @Test func emptyLists() {
        model.load()
        #expect(model.isLoaded)
        #expect(model.habits.isEmpty)
        #expect(model.oneTimeGroups.isEmpty)
    }

    @Test func weekdaySummaries() {
        let calendar = TestEnvironment.calendar
        #expect(ScheduleFormatter.weekdays(.all, calendar: calendar) == "Every day")
        #expect(
            ScheduleFormatter.weekdays([.monday, .tuesday, .wednesday, .thursday, .friday], calendar: calendar)
                == "Weekdays")
        #expect(ScheduleFormatter.weekdays([.saturday, .sunday], calendar: calendar) == "Weekends")
        #expect(ScheduleFormatter.weekdays([.friday, .monday, .wednesday], calendar: calendar) == "Mon, Wed, Fri")
        #expect(ScheduleFormatter.timing(.anytime) == "Anytime")
        #expect(ScheduleFormatter.timing(.part(.night)) == "Night")
    }
}
