import Core
import Foundation

/// Missed queries for the app: today's missed count for the tab badge, the Missed tab's lists, and the
/// popup's seen list (SPEC F-08, §5.8).
@MainActor
final class MissedManager {
    private let tasks: TaskManager
    private let deviceState: DeviceState
    private let clock: any Clock

    init(tasks: TaskManager, deviceState: DeviceState, clock: any Clock) {
        self.tasks = tasks
        self.deviceState = deviceState
        self.clock = clock
    }

    /// Today's Missed and Short occurrences.
    func missedToday() throws -> [MissedItem] {
        MissedQueries.missedToday(in: try tasks.snapshot(), now: clock.now)
    }

    /// Missed today that the popup hasn't shown yet (SPEC §5.8). A seen list from another day counts as empty.
    func unseenToday() throws -> [MissedItem] {
        MissedQueries.unseen(in: try tasks.snapshot(), now: clock.now, seen: deviceState.missedSeen)
    }

    /// What the missed popup should show now: nothing when the app was opened from a widget or a notification
    /// (it waits for the next normal open), otherwise today's unseen missed tasks (SPEC F-08).
    func popupItems(openedFromLink: Bool) -> [MissedItem] {
        guard !openedFromLink else { return [] }
        do {
            return try unseenToday()
        } catch {
            Log.tasks.error("Couldn't check for missed tasks: \(error)")
            return []
        }
    }

    /// Records that the popup showed these occurrences. The list starts over each day (SPEC F-08).
    func markSeen(_ occurrenceIDs: [String]) {
        let today = DayKey(clock.now, calendar: clock.calendar)
        var seen = deviceState.missedSeen.flatMap { $0.day == today ? $0 : nil } ?? MissedSeenList(day: today)
        seen.occurrenceIDs.formUnion(occurrenceIDs)
        deviceState.missedSeen = seen
    }

    /// The Missed tab's badge: how many tasks are Missed or Short today.
    func missedTodayCount() -> Int {
        do {
            return try missedToday().count
        } catch {
            Log.tasks.error("Couldn't count today's missed tasks: \(error)")
            return 0
        }
    }
}
