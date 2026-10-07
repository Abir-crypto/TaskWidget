import Core
import SwiftUI

/// An upcoming one-time task in Tasks › One-time: title and timing (SPEC F-11).
struct OneTimeRow: View {
    let item: DayItem

    var body: some View {
        HStack {
            Text(item.task.title)
            Spacer(minLength: 8)
            Text(ScheduleFormatter.timing(item.occurrence.timing))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let task = TaskValue(
        title: "Renew passport", type: .oneTime, date: DayKey(year: 2026, month: 10, day: 6), createdAt: .now)
    let schedule = ScheduleValue(
        taskID: task.id, effectiveFrom: .distantPast, timing: .part(.noon), weekdays: .none, createdAt: .now)
    let occurrence = Occurrence(task: task, day: DayKey(year: 2026, month: 10, day: 6), schedule: schedule)
    return List { OneTimeRow(item: DayItem(occurrence: occurrence, status: .open, minutes: 0, targetMinutes: nil)) }
}
