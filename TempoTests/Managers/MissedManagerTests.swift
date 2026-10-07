import Core
import Foundation
import Testing

@testable import Tempo

@MainActor
struct MissedManagerTests {
    private let clock = TestEnvironment.clock(hour: 9)
    private let store: SwiftDataTaskStore
    private let tasks: TaskManager
    private let missed: MissedManager

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        tasks = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
        missed = MissedManager(tasks: tasks, deviceState: TestEnvironment.deviceState(), clock: clock)
    }

    @Test func badgeCountsTodaysMissedAndShort() throws {
        try tasks.createOneTime(title: "Morning", date: tasks.today, timing: .part(.morning))
        let read = try tasks.createHabit(
            type: .duration, title: "Read", timing: .part(.morning), weekdays: .all, startDay: tasks.today,
            lengthDays: nil, targetMinutes: 30)
        try tasks.logTime(taskID: read.id, minutes: 10)
        try tasks.createOneTime(title: "Evening", date: tasks.today, timing: .part(.evening))
        #expect(missed.missedTodayCount() == 0)
        clock.now = TestEnvironment.date(2026, 10, 6, 12, 0)
        #expect(missed.missedTodayCount() == 2)
    }
}

@MainActor
struct MissedPopupTests {
    private let clock = TestEnvironment.clock(hour: 9)
    private let store: SwiftDataTaskStore
    private let tasks: TaskManager
    private let deviceState = TestEnvironment.deviceState()
    private let missed: MissedManager

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        tasks = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
        missed = MissedManager(tasks: tasks, deviceState: deviceState, clock: clock)
    }

    @Test func normalOpenWithUnseenMissedTasksShowsThem() throws {
        let call = try tasks.createOneTime(title: "Call", date: tasks.today, timing: .part(.morning))
        #expect(missed.popupItems(openedFromLink: false).isEmpty)  // nothing missed yet at 09:00
        clock.now = TestEnvironment.date(2026, 10, 6, 12, 0)
        #expect(missed.popupItems(openedFromLink: false).map(\.occurrence.task.id) == [call.id])
    }

    @Test func openingFromALinkShowsNothingAndTheNextNormalOpenDoes() throws {
        try tasks.createOneTime(title: "Call", date: tasks.today, timing: .part(.morning))
        clock.now = TestEnvironment.date(2026, 10, 6, 12, 0)
        #expect(missed.popupItems(openedFromLink: true).isEmpty)
        #expect(missed.popupItems(openedFromLink: false).count == 1)
        // The badge still counts it in the meantime.
        #expect(missed.missedTodayCount() == 1)
    }

    @Test func aSeenTaskNeverShowsAgainToday() throws {
        try tasks.createOneTime(title: "Call", date: tasks.today, timing: .part(.morning))
        clock.now = TestEnvironment.date(2026, 10, 6, 12, 0)
        missed.markSeen(missed.popupItems(openedFromLink: false).map(\.id))
        #expect(missed.popupItems(openedFromLink: false).isEmpty)
        // A task missed later the same day is new.
        clock.now = TestEnvironment.date(2026, 10, 6, 12, 1)
        let noon = try tasks.createOneTime(title: "Noon", date: tasks.today, timing: .part(.noon))
        clock.now = TestEnvironment.date(2026, 10, 6, 17, 0)
        #expect(missed.popupItems(openedFromLink: false).map(\.occurrence.task.id) == [noon.id])
    }

    @Test func theSeenListResetsTheNextDay() throws {
        try tasks.createOneTime(title: "Call", date: tasks.today, timing: .part(.morning))
        clock.now = TestEnvironment.date(2026, 10, 6, 12, 0)
        missed.markSeen(missed.popupItems(openedFromLink: false).map(\.id))
        #expect(deviceState.missedSeen?.day == TestEnvironment.today)

        clock.now = TestEnvironment.date(2026, 10, 7, 12, 0)
        let tomorrow = try tasks.createOneTime(title: "Tomorrow", date: tasks.today, timing: .part(.noon))
        clock.now = TestEnvironment.date(2026, 10, 7, 17, 0)
        let items = missed.popupItems(openedFromLink: false)
        #expect(items.map(\.occurrence.task.id) == [tomorrow.id])
        missed.markSeen(items.map(\.id))
        #expect(deviceState.missedSeen?.day == DayKey(year: 2026, month: 10, day: 7))
        #expect(deviceState.missedSeen?.occurrenceIDs.count == 1)
    }

    @Test func reviewSwitchesToMissedAndHighlights() {
        let router = NavigationRouter()
        router.missedPopup = MissedPopupContent(items: [])
        router.reviewMissed(["a_20261006"])
        #expect(router.selectedTab == .missed)
        #expect(router.missedHighlight == ["a_20261006"])
        #expect(router.missedPopup == nil)
    }
}
