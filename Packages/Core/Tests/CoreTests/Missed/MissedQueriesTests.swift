import Foundation
import Testing

@testable import Core

struct MissedQueriesTests {
    private let now = TestCalendar.today(18)

    @Test func missedTodayIncludesShort() {
        var fixtures = Fixtures()
        let missed = fixtures.oneTime("Call", timing: .part(.morning))
        let read = fixtures.duration("Read", timing: .part(.noon), target: 30)
        fixtures.log(read, minutes: 20, on: TestCalendar.today)
        fixtures.oneTime("Later", timing: .part(.night))
        let done = fixtures.habit("Done", timing: .part(.morning))
        fixtures.complete(done, on: TestCalendar.today)

        let items = MissedQueries.missedToday(in: fixtures.snapshot(), now: now)
        #expect(items.map(\.occurrence.task.id) == [missed.id, read.id])
        #expect(items.map(\.status) == [.missed, .short])
        #expect(items.last?.minutes == 20)
        #expect(items.last?.targetMinutes == 30)
        #expect(items.first?.targetMinutes == nil)
    }

    /// Mon 28 Sep – Mon 5 Oct, with a mix of types and parts, all missed.
    private func earlierFixtures() -> (Fixtures, [String: TaskValue]) {
        var fixtures = Fixtures()
        var tasks: [String: TaskValue] = [:]
        tasks["oneTime"] = fixtures.oneTime(
            "Passport", on: DayKey(year: 2026, month: 9, day: 29), timing: .fixed(minute: 750))
        tasks["progress"] = fixtures.habit(
            "Medicine", timing: .part(.morning), weekdays: [.monday], start: DayKey(year: 2026, month: 9, day: 28))
        tasks["duration"] = fixtures.duration(
            "Read", timing: .part(.evening), weekdays: [.saturday], start: DayKey(year: 2026, month: 9, day: 28))
        tasks["anytime"] = fixtures.oneTime("Anytime", on: TestCalendar.oct(5), timing: .anytime)
        return (fixtures, tasks)
    }

    @Test func missedEarlierListsEveryPastMissNewestFirst() {
        let (fixtures, tasks) = earlierFixtures()
        let items = MissedQueries.missedEarlier(in: fixtures.snapshot(), now: now)
        // 5 Oct: Medicine (Morning), Anytime. 3 Oct: Read. 29 Sep: Passport. 28 Sep: Medicine.
        #expect(items.map(\.day.rawValue) == [20_261_005, 20_261_005, 20_261_003, 20_260_929, 20_260_928])
        #expect(items.prefix(2).map(\.occurrence.task.id) == [tasks["progress"]?.id, tasks["anytime"]?.id])
    }

    @Test func oldestFirst() {
        let (fixtures, _) = earlierFixtures()
        let items = MissedQueries.missedEarlier(
            in: fixtures.snapshot(), now: now, filter: MissedFilter(sort: .oldestFirst))
        #expect(items.map(\.day.rawValue) == [20_260_928, 20_260_929, 20_261_003, 20_261_005, 20_261_005])
    }

    @Test func todayIsNotEarlier() {
        var fixtures = Fixtures()
        fixtures.oneTime("Today", timing: .part(.morning))
        #expect(MissedQueries.missedEarlier(in: fixtures.snapshot(), now: now).isEmpty)
    }

    @Test func filterByType() {
        let (fixtures, tasks) = earlierFixtures()
        let filter = MissedFilter(types: [.duration, .oneTime])
        let ids = Set(
            MissedQueries.missedEarlier(in: fixtures.snapshot(), now: now, filter: filter).map(\.occurrence.task.id))
        #expect(ids == Set([tasks["duration"]?.id, tasks["oneTime"]?.id, tasks["anytime"]?.id].compactMap { $0 }))
        #expect(filter.isActive)
    }

    @Test func filterByPartCountsFixedTimesUnderTheirPart() {
        let (fixtures, tasks) = earlierFixtures()
        let noon = MissedQueries.missedEarlier(in: fixtures.snapshot(), now: now, filter: MissedFilter(parts: [.noon]))
        #expect(noon.map(\.occurrence.task.id) == [tasks["oneTime"]?.id])
        let anytime = MissedQueries.missedEarlier(
            in: fixtures.snapshot(), now: now, filter: MissedFilter(parts: [.anytime]))
        #expect(anytime.map(\.occurrence.task.id) == [tasks["anytime"]?.id])
    }

    @Test func filterByTask() {
        let (fixtures, tasks) = earlierFixtures()
        let filter = MissedFilter(taskID: tasks["progress"]?.id)
        let items = MissedQueries.missedEarlier(in: fixtures.snapshot(), now: now, filter: filter)
        #expect(items.map(\.day.rawValue) == [20_261_005, 20_260_928])
    }

    @Test func filterByDateRange() {
        let (fixtures, _) = earlierFixtures()
        let snapshot = fixtures.snapshot()
        let week = MissedQueries.missedEarlier(in: snapshot, now: now, filter: MissedFilter(dateRange: .thisWeek))
        #expect(week.map(\.day.rawValue) == [20_261_005, 20_261_005])
        let month = MissedQueries.missedEarlier(in: snapshot, now: now, filter: MissedFilter(dateRange: .thisMonth))
        #expect(month.map(\.day.rawValue) == [20_261_005, 20_261_005, 20_261_003])
        let custom = MissedQueries.missedEarlier(
            in: snapshot, now: now,
            filter: MissedFilter(
                dateRange: .custom(first: DayKey(year: 2026, month: 9, day: 29), last: TestCalendar.oct(3))))
        #expect(custom.map(\.day.rawValue) == [20_261_003, 20_260_929])
    }

    @Test func combinedFiltersAndClearing() {
        let (fixtures, _) = earlierFixtures()
        let filter = MissedFilter(sort: .oldestFirst, dateRange: .thisMonth, types: [.progress], parts: [.morning])
        let items = MissedQueries.missedEarlier(in: fixtures.snapshot(), now: now, filter: filter)
        #expect(items.map(\.day.rawValue) == [20_261_005])
        #expect(filter.cleared == MissedFilter(sort: .oldestFirst))
        #expect(!filter.cleared.isActive)
        #expect(!MissedFilter(sort: .oldestFirst).isActive)
    }

    @Test func endedHabitsStayAndDeletedTasksGo() {
        var fixtures = Fixtures()
        let ended = fixtures.habit(
            "Ended", timing: .part(.morning), start: TestCalendar.oct(4), endedOn: TestCalendar.oct(4))
        let deleted = fixtures.habit("Deleted", timing: .part(.morning), start: TestCalendar.oct(4))
        fixtures.delete(deleted)
        let items = MissedQueries.missedEarlier(in: fixtures.snapshot(), now: now)
        #expect(items.map(\.occurrence.task.id) == [ended.id])
    }

    @Test func doneAndShortOnPastDays() {
        var fixtures = Fixtures()
        let read = fixtures.duration("Read", timing: .part(.evening), start: TestCalendar.oct(4), target: 30)
        fixtures.log(read, minutes: 10, on: TestCalendar.oct(4))
        fixtures.log(read, minutes: 30, on: TestCalendar.oct(5))
        let items = MissedQueries.missedEarlier(in: fixtures.snapshot(), now: now)
        #expect(items.map(\.day) == [TestCalendar.oct(4)])
        #expect(items.first?.status == .short)
        #expect(items.first?.minutes == 10)
    }

    @Test func unseenExcludesTheSeenList() throws {
        var fixtures = Fixtures()
        let seen = fixtures.oneTime("Seen", timing: .part(.morning))
        let fresh = fixtures.oneTime("Fresh", timing: .part(.morning))
        let snapshot = fixtures.snapshot()
        let seenID = Occurrence.id(taskID: seen.id, day: TestCalendar.today)
        let list = MissedSeenList(day: TestCalendar.today, occurrenceIDs: [seenID])
        #expect(MissedQueries.unseen(in: snapshot, now: now, seen: list).map(\.occurrence.task.id) == [fresh.id])
        let stale = MissedSeenList(day: TestCalendar.oct(5), occurrenceIDs: [seenID])
        #expect(MissedQueries.unseen(in: snapshot, now: now, seen: stale).count == 2)
        #expect(MissedQueries.unseen(in: snapshot, now: now, seen: nil).count == 2)
    }

    @Test func dateBounds() {
        let calendar = TestCalendar.london
        let month = MissedQueries.dateBounds(.thisMonth, today: TestCalendar.today, calendar: calendar)
        #expect(month.first == TestCalendar.oct(1))
        #expect(month.last == TestCalendar.oct(31))
        let february = MissedQueries.dateBounds(
            .thisMonth, today: DayKey(year: 2028, month: 2, day: 10), calendar: calendar)
        #expect(february.last == DayKey(year: 2028, month: 2, day: 29))
        let week = MissedQueries.dateBounds(.thisWeek, today: TestCalendar.today, calendar: calendar)
        #expect(week.first == TestCalendar.oct(5))
        #expect(week.last == TestCalendar.oct(11))
    }

    // MARK: Correction window (SPEC F-08, §5.11, T-41)

    /// During the window, yesterday's misses move from Earlier to the correctable list; after it, they're back.
    @Test func yesterdayMovesOutOfEarlierDuringTheWindow() {
        let (fixtures, tasks) = earlierFixtures()
        let snapshot = fixtures.snapshot()
        let morning = TestCalendar.today(9)
        let open = EditWindow(now: morning, parts: snapshot.parts, calendar: snapshot.calendar)
        let correctable = MissedQueries.missedCorrectable(in: snapshot, now: morning, window: open)
        #expect(correctable.map(\.occurrence.task.id) == [tasks["progress"]?.id, tasks["anytime"]?.id])
        let earlier = MissedQueries.missedEarlier(in: snapshot, now: morning, window: open)
        #expect(earlier.map(\.day.rawValue) == [20_261_003, 20_260_929, 20_260_928])

        let closed = EditWindow(now: now, parts: snapshot.parts, calendar: snapshot.calendar)
        #expect(MissedQueries.missedCorrectable(in: snapshot, now: now, window: closed).isEmpty)
        #expect(MissedQueries.missedEarlier(in: snapshot, now: now, window: closed).count == 5)
    }
}
