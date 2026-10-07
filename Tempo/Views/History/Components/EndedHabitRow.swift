import Core
import SwiftUI

/// An ended habit in History: title, result, end date and Start again (SPEC F-12).
struct EndedHabitRow: View {
    let habit: EndedHabit
    let onStartAgain: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: habit.task.type.systemImage)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 28)
                .accessibilityLabel(habit.task.type.title)
            VStack(alignment: .leading, spacing: 3) {
                Text(habit.task.title)
                Text(habit.result)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.tint)
                Text(habit.ended)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Button("Start again", action: onStartAgain)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityHint(Text("Creates the same habit again, starting today"))
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    let task = TaskValue(
        title: "Medicine", type: .progress, startDay: DayKey(year: 2026, month: 9, day: 1), createdAt: .now)
    return List {
        EndedHabitRow(habit: EndedHabit(task: task, result: "Done 27 of 30 days", ended: "Ended Wed 30 Sep")) {}
    }
}
