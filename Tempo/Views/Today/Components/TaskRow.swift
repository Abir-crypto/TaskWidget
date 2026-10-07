import Core
import SwiftUI

/// A one-time task or progress habit on Today: a checkbox, the title, and its time if fixed (SPEC F-10).
struct TaskRow: View {
    let item: DayItem
    let canComplete: Bool
    let onToggle: () -> Void

    private var isDone: Bool { item.status == .done }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isDone ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            }
            .buttonStyle(.borderless)
            .disabled(!canComplete)
            .accessibilityLabel(isDone ? Text("Mark not done") : Text("Mark done"))
            .accessibilityValue(Text(item.task.title))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.task.title)
                    .strikethrough(isDone)
                    .foregroundStyle(isDone ? .secondary : .primary)
                if item.task.type == .progress {
                    Label("Habit", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .labelStyle(.titleAndIcon)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                if let minute = item.occurrence.timing.fixedMinute {
                    Text(TimeOfDayFormatter.string(minute: minute))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                if item.status == .missed {
                    StatusLabel(status: .missed).font(.caption.weight(.semibold))
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    let calendar = Calendar.autoupdatingCurrent
    let now = DayKey(year: 2026, month: 10, day: 6).date(atMinute: 780, in: calendar)
    let task = TaskValue(
        title: "Interview", type: .oneTime, date: DayKey(year: 2026, month: 10, day: 6), createdAt: now)
    let schedule = ScheduleValue(
        taskID: task.id, effectiveFrom: .distantPast, timing: .fixed(minute: 750), weekdays: .none, createdAt: now)
    let occurrence = Occurrence(task: task, day: DayKey(year: 2026, month: 10, day: 6), schedule: schedule)
    return List {
        TaskRow(item: DayItem(occurrence: occurrence, status: .open, minutes: 0, targetMinutes: nil), canComplete: true)
        {}
        TaskRow(item: DayItem(occurrence: occurrence, status: .done, minutes: 0, targetMinutes: nil), canComplete: true)
        {}
        TaskRow(
            item: DayItem(occurrence: occurrence, status: .missed, minutes: 0, targetMinutes: nil), canComplete: true
        ) {}
    }
}
