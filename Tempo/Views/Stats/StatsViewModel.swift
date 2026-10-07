import Core
import Foundation
import Observation

/// State for the Stats screen (SPEC F-14): a week, month or year, its cards, and where it can move.
@Observable
@MainActor
final class StatsViewModel {
    private(set) var range: StatsRange
    private(set) var stats: StatsSnapshot?
    private(set) var firstDay: DayKey?

    private let manager: StatsManager
    private let clock: any Clock

    init(manager: StatsManager, clock: any Clock) {
        self.manager = manager
        self.clock = clock
        let today = DayKey(clock.now, calendar: clock.calendar)
        self.range = StatsRange.containing(today, kind: .week, calendar: clock.calendar)
    }

    var calendar: Calendar { clock.calendar }
    var today: DayKey { DayKey(clock.now, calendar: calendar) }

    var kind: StatsRangeKind {
        get { range.kind }
        set {
            guard newValue != range.kind else { return }
            range = StatsRange.containing(today, kind: newValue, calendar: calendar)
            load()
        }
    }

    func load() {
        do {
            let result = try manager.stats(for: range)
            stats = result.snapshot
            firstDay = result.firstDay
        } catch {
            Log.tasks.error("Couldn't load Stats: \(error)")
        }
    }

    // MARK: Moving between ranges

    var canGoBack: Bool { range.canGoBack(firstDay: firstDay, calendar: calendar) }
    var canGoForward: Bool { range.canGoForward(today: today, calendar: calendar) }

    func goBack() {
        guard canGoBack else { return }
        range = range.previous(in: calendar)
        load()
    }

    func goForward() {
        guard canGoForward else { return }
        range = range.next(in: calendar)
        load()
    }

    /// Tapping a month in the Year chart shows that month (D-083).
    func showMonth(_ month: MonthRate) {
        range = StatsRange.containing(
            DayKey(year: month.year, month: month.month, day: 1), kind: .month, calendar: calendar)
        load()
    }

    // MARK: Text

    /// "5 – 11 Oct", "October 2026" or "2026".
    var rangeTitle: String {
        let first = range.first.startDate(in: calendar)
        switch range.kind {
        case .week:
            let last = range.last.startDate(in: calendar)
            return (first..<last).formatted(
                Date.IntervalFormatStyle(
                    date: .abbreviated, time: .omitted, calendar: calendar, timeZone: calendar.timeZone))
        case .month:
            return first.formatted(
                Date.FormatStyle(calendar: calendar, timeZone: calendar.timeZone).month(.wide).year())
        case .year:
            return String(range.first.year)
        }
    }

    /// "up 8 points from last week", "down 3 points from last month", "same as last year", or `nil`.
    var changeText: String? {
        guard let change = stats?.change else { return nil }
        let period: String
        switch range.kind {
        case .week: period = String(localized: "last week")
        case .month: period = String(localized: "last month")
        case .year: period = String(localized: "last year")
        }
        if change > 0 { return String(localized: "up \(change) points from \(period)") }
        if change < 0 { return String(localized: "down \(-change) points from \(period)") }
        return String(localized: "same as \(period)")
    }
}
