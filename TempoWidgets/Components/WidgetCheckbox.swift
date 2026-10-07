import Core
import SwiftUI
import WidgetKit

/// A round checkbox row for widgets: a button that marks the task done, or not done (SPEC F-21, D-090).
struct WidgetCheckbox: View {
    let item: DayItem

    private var isDone: Bool { item.status == .done }

    var body: some View {
        Button(intent: ToggleCompletionIntent(taskID: item.task.id, day: item.occurrence.day, done: !isDone)) {
            HStack(spacing: 8) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isDone ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    .widgetAccentable()
                Text(item.task.title)
                    .font(.subheadline)
                    .strikethrough(isDone)
                    .foregroundStyle(isDone ? .secondary : .primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isDone ? Text("Mark not done") : Text("Mark done"))
        .accessibilityValue(Text(item.task.title))
    }
}
