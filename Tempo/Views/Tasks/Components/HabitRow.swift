import Core
import SwiftUI

/// A habit in Tasks › Habits: title, type icon, schedule and progress (SPEC F-11).
struct HabitRow: View {
    let habit: HabitSummary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: habit.task.type.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
                .accessibilityLabel(habit.task.type.title)
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(habit.task.title)
                    if habit.task.notes != nil { NotesIndicator() }
                }
                Text(habit.schedule)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(habit.progress)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.tint)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let task = TaskValue(
        title: "Read", type: .duration, startDay: DayKey(year: 2026, month: 10, day: 1), createdAt: .now)
    return List {
        HabitRow(
            habit: HabitSummary(task: task, schedule: "Every day · Evening", progress: "2h 10m of 3h 30m this week"))
    }
}
