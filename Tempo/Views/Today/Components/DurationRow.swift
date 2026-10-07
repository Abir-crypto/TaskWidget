import Core
import SwiftUI

/// A duration habit on Today: the title, progress ("10 of 30 min") and ▶, and Done once the target is reached
/// (SPEC F-10).
struct DurationRow: View {
    let item: DayItem
    /// Starts a timer for the habit. `nil` hides ▶: while a timer exists, or when time can't be logged today.
    var onStart: (() -> Void)?

    private var target: Int { item.targetMinutes ?? 0 }
    private var progress: Double { target > 0 ? min(Double(item.minutes) / Double(target), 1) : 0 }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().stroke(.quaternary, lineWidth: 3)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: item.status == .done ? "checkmark" : "timer")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.tint)
            }
            .frame(width: 24, height: 24)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.task.title)
                Text(DurationFormatter.progress(minutes: item.minutes, target: target))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                if let minute = item.occurrence.timing.fixedMinute {
                    Text(TimeOfDayFormatter.string(minute: minute))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                StatusLabel(status: item.status).font(.caption.weight(.semibold))
            }
            if let onStart {
                Button(action: onStart) {
                    Image(systemName: "play.circle.fill")
                        .font(.title)
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(Text("Start timer"))
                .accessibilityValue(Text(item.task.title))
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    let calendar = Calendar.autoupdatingCurrent
    let now = DayKey(year: 2026, month: 10, day: 6).date(atMinute: 780, in: calendar)
    let task = TaskValue(
        title: "Read", type: .duration, startDay: DayKey(year: 2026, month: 10, day: 1), createdAt: now)
    let schedule = ScheduleValue(
        taskID: task.id, effectiveFrom: .distantPast, timing: .part(.evening), weekdays: .all, targetMinutes: 30,
        createdAt: now)
    let occurrence = Occurrence(task: task, day: DayKey(year: 2026, month: 10, day: 6), schedule: schedule)
    return List {
        DurationRow(item: DayItem(occurrence: occurrence, status: .open, minutes: 10, targetMinutes: 30))
        DurationRow(item: DayItem(occurrence: occurrence, status: .done, minutes: 35, targetMinutes: 30))
        DurationRow(item: DayItem(occurrence: occurrence, status: .short, minutes: 20, targetMinutes: 30))
    }
}
