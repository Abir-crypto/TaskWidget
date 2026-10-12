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

    /// What the missed popup should show now: nothing in the Gentle style (SPEC F-30), nothing when the app was
    /// opened from a widget or a notification (it waits for the next normal open), otherwise today's unseen missed
    /// tasks (SPEC F-08).
    func popupItems(openedFromLink: Bool) -> [MissedItem] {
        guard !openedFromLink else { return [] }
        do {
            let snapshot = try tasks.snapshot()
            guard snapshot.settings.missedStyle.showsBadgeAndPopup else { return [] }
            return MissedQueries.unseen(in: snapshot, now: clock.now, seen: deviceState.missedSeen)
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

    /// Switching from Gentle to Strict: today's tasks missed so far count as seen, so the popup only shows tasks
    /// missed after the switch (SPEC F-30). The popup never ran in Gentle, so nothing filled the list there.
    func markMissedTodaySeen() {
        do {
            markSeen(try missedToday().map(\.id))
        } catch {
            Log.tasks.error("Couldn't mark today's missed tasks as seen: \(error)")
        }
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
