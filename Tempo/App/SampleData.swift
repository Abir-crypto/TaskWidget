import Core
import Foundation

/// A realistic set of tasks for previews and UI tests (`-ui-testing-sample`). It writes straight to the
/// store so it can include history before today; the app itself never uses it.
@MainActor
enum SampleData {
    static func populate(store: any TaskStore, clock: any Clock) {
        let calendar = clock.calendar
        let today = DayKey(clock.now, calendar: calendar)
        let weekAgo = today.adding(days: -7, in: calendar)
        let created = weekAgo.date(atMinute: 480, in: calendar)
        var writes: [StoreWrite] = []
        var order = 0.0

        func add(
            _ title: String, _ type: TaskType, _ timing: Timing, date: DayKey? = nil, start: DayKey? = nil,
            weekdays: Weekdays = .all, target: Int? = nil
        ) -> UUID {
            order += 1
            let task = TaskValue(
                title: title, type: type, date: type == .oneTime ? (date ?? today) : nil,
                startDay: type.isHabit ? (start ?? weekAgo) : nil, createdAt: created.addingTimeInterval(order))
            writes.append(.task(task))
            writes.append(
                .schedule(
                    ScheduleValue(
                        taskID: task.id, effectiveFrom: type.isHabit ? (start ?? weekAgo) : .distantPast,
                        timing: timing, weekdays: type.isHabit ? weekdays : .none, targetMinutes: target,
                        createdAt: task.createdAt)))
            return task.id
        }

        func complete(_ id: UUID, _ day: DayKey) {
            writes.append(.completion(CompletionValue(taskID: id, day: day, createdAt: created)))
        }

        func log(_ id: UUID, _ minutes: Int, _ day: DayKey) {
            writes.append(
                .timeEntry(
                    TimeEntryValue(taskID: id, day: day, seconds: minutes * 60, source: .manual, createdAt: created)))
        }

        let medicine = add("Take medicine", .progress, .part(.morning))
        let stretch = add("Stretch", .oneTime, .part(.morning))
        _ = stretch
        _ = add("Interview", .oneTime, .fixed(minute: 750))
        _ = add("Call the bank", .oneTime, .part(.noon))
        let gym = add("Gym", .progress, .part(.evening), weekdays: [.monday, .tuesday, .wednesday, .friday])
        let read = add("Read", .duration, .part(.evening), target: 30)
        _ = add("Plan tomorrow", .oneTime, .part(.night))
        _ = add("Renew passport", .oneTime, .anytime)
        _ = add("Pick up the parcel", .oneTime, .part(.noon), date: today.adding(days: 2, in: calendar))

        for offset in 1...7 {
            let day = today.adding(days: -offset, in: calendar)
            if offset != 3 { complete(medicine, day) }
            if offset % 2 == 0 { complete(gym, day) }
            log(read, offset == 4 ? 0 : [35, 20, 30, 0, 45, 10, 30][offset - 1], day)
        }
        complete(medicine, today)
        log(read, 10, today)

        do {
            try store.write(
                writes.filter {
                    if case .timeEntry(let entry) = $0 { return entry.seconds > 0 }
                    return true
                })
            if try store.settings() == nil { try store.save(SettingsValue.defaults) }
        } catch {
            Log.storage.error("Sample data failed: \(error)")
        }
    }
}
