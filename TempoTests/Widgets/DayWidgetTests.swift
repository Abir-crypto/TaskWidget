import Core
import Foundation
import Testing

@testable import Tempo

/// SPEC T-25: the Day widget's columns, marks, labels, footer and states.
@MainActor
struct DayWidgetTests {
    private let clock = TestEnvironment.clock(hour: 9)
    private let store: SwiftDataTaskStore
    private let tasks: TaskManager

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        try store.save(SettingsValue.defaults)
        tasks = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
    }

    private func content(at date: Date? = nil) throws -> DayWidgetContent {
        DayWidgetContent(
            snapshot: try SnapshotLoader.load(store: store, deviceState: TestEnvironment.deviceState(), clock: clock),
            at: date ?? clock.now)
    }

    @discardableResult
    private func make(_ title: String, _ timing: Timing) throws -> TaskValue {
        clock.advance(by: 1)
        return try tasks.createOneTime(title: title, date: tasks.today, timing: timing)
    }

    @Test func columnsMarksAndLabels() throws {
        let done = try make("Done", .part(.morning))
        try tasks.complete(taskID: done.id, day: tasks.today)
        try make("Missed later", .part(.morning))
        let read = try tasks.createHabit(
            type: .duration, title: "Read", timing: .part(.noon), weekdays: .all, startDay: tasks.today,
            lengthDays: nil,
            targetMinutes: 30)
        try tasks.logTime(taskID: read.id, minutes: 10)
        try make("Evening", .part(.evening))
        clock.now = TestEnvironment.date(2026, 10, 6, 13)
        let content = try content()
        #expect(content.columns.map(\.part) == [.morning, .noon, .evening, .night])
        #expect(content.columns.map(\.isCurrent) == [false, true, false, false])
        #expect(content.columns[0].marks == [.done, .missed])
        #expect(content.columns[0].leftCount == 0)
        #expect(content.columns[1].marks == [.partial])
        #expect(content.columns[1].leftCount == 1)
        #expect(content.columns[2].marks == [.notDone])
        #expect(!content.columns[3].hasTasks)
        #expect(!content.isAllDone)
    }

    @Test func moreThanSixMarksShowPlusN() throws {
        for index in 0..<8 { try make("Noon \(index)", .part(.noon)) }
        let noon = try content().columns[1]
        #expect(noon.marks.count == 6)
        #expect(noon.extraCount == 2)
    }

    @Test func anytimeFooterAndStates() throws {
        #expect(try content().hasNoTasks)
        let anytime = try make("Anytime", .anytime)
        #expect(try content().anytimeLeft == 1)
        try tasks.complete(taskID: anytime.id, day: tasks.today)
        let content = try content()
        #expect(content.anytimeLeft == 0)
        #expect(content.isAllDone)
        #expect(!content.hasNoTasks)
    }

    @Test func eachColumnOpensTodayAtItsPart() {
        #expect(DeepLink(url: DeepLink.today(part: .evening).url) == .today(part: .evening))
    }
}
