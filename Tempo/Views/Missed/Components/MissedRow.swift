import Core
import SwiftUI

/// A missed task: title, type icon, when it was due and, for duration habits, its minutes (SPEC F-08).
struct MissedRow: View {
    let item: MissedItem
    let dueText: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.occurrence.type.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 24)
                .accessibilityLabel(item.occurrence.type.title)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.occurrence.task.title)
                Text(dueText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if let target = item.targetMinutes, item.status == .short {
                Text(DurationFormatter.progress(minutes: item.minutes, target: target))
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                    .monospacedDigit()
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle")
                    Text("Missed")
                }
                .font(.subheadline)
                .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let task = TaskValue(
        title: "Call the bank", type: .oneTime, date: DayKey(year: 2026, month: 9, day: 29), createdAt: .now)
    let schedule = ScheduleValue(
        taskID: task.id, effectiveFrom: .distantPast, timing: .part(.noon), weekdays: .none, createdAt: .now)
    let occurrence = Occurrence(task: task, day: DayKey(year: 2026, month: 9, day: 29), schedule: schedule)
    return List {
        MissedRow(
            item: MissedItem(occurrence: occurrence, status: .missed, minutes: 0, targetMinutes: nil),
            dueText: "Tue 29 Sep · Noon")
    }
}
