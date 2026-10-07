import Core
import SwiftUI

/// A completed one-time task in History. Today's can be marked not done (SPEC F-12).
struct CompletedTaskRow: View {
    let item: CompletedTask
    let onMarkNotDone: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onMarkNotDone) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(item.canUndo ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            }
            .buttonStyle(.borderless)
            .disabled(!item.canUndo)
            .accessibilityLabel(Text("Mark not done"))
            .accessibilityValue(Text(item.task.title))
            Text(item.task.title)
                .foregroundStyle(.secondary)
                .strikethrough()
            Spacer()
        }
    }
}

#Preview {
    let task = TaskValue(
        title: "Renew passport", type: .oneTime, date: DayKey(year: 2026, month: 10, day: 6), createdAt: .now)
    return List {
        CompletedTaskRow(
            item: CompletedTask(
                task: task, completedOn: DayKey(year: 2026, month: 10, day: 6), completedAt: .now, canUndo: true)
        ) {}
    }
}
