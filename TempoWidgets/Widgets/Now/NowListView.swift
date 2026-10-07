import Core
import SwiftUI
import WidgetKit

/// The Now widget's list mode (SPEC F-21).
struct NowListView: View {
    let list: NowList
    let date: Date
    let calendar: Calendar

    var body: some View {
        if list.hasNoTasks {
            message("No tasks today", systemImage: "sun.max")
                .widgetURL(DeepLink.newTask(day: DayKey(date, calendar: calendar)).url)
        } else if list.isFree {
            VStack(spacing: 0) {
                message("You're free today", systemImage: "checkmark.seal")
                footer
            }
            .widgetURL(DeepLink.today().url)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                if let clock = list.genericTimer {
                    HStack(spacing: 4) {
                        Image(systemName: "timer").accessibilityHidden(true)
                        Text("Timer running ·")
                        WidgetClock(value: clock)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tint)
                    .widgetAccentable()
                }
                ForEach(Array(list.groups.enumerated()), id: \.offset) { index, group in
                    if index == 0 {
                        header(group)
                    } else {
                        Text(title(of: group.section))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                    ForEach(group.items) { item in
                        row(item)
                    }
                }
                Spacer(minLength: 0)
                if list.hiddenCount > 0 {
                    Link(destination: DeepLink.today().url) {
                        Text("+\(list.hiddenCount) more")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tint)
                    }
                }
                footer
            }
            .widgetURL(DeepLink.today().url)
        }
    }

    // MARK: Header and rows

    private func header(_ group: NowList.Group) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title(of: group.section))
                .font(.headline)
                .widgetAccentable()
            if group.section.phase == .current, group.section.part != nil {
                Text("ends in ") + Text(endDate(of: group.section), style: .relative)
            } else if let part = group.section.part {
                Text("from \(TimeOfDayFormatter.string(minute: group.section.window.lowerBound))")
                    .accessibilityLabel(
                        Text(
                            "\(part.title) starts at \(TimeOfDayFormatter.string(minute: group.section.window.lowerBound))"
                        ))
            }
            Spacer()
            Text("\(list.leftCount) left")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func row(_ item: DayItem) -> some View {
        if item.task.type == .duration {
            HStack(spacing: 8) {
                Image(systemName: item.status == .done ? "checkmark.circle.fill" : "timer")
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .widgetAccentable()
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(item.task.title).font(.subheadline).lineLimit(1)
                    Text(DurationFormatter.progress(minutes: item.minutes, target: item.targetMinutes ?? 0))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                if list.canStartTimers {
                    Button(intent: StartHabitTimerIntent(taskID: item.task.id)) {
                        Image(systemName: "play.fill")
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel(Text("Start timer for \(item.task.title)"))
                }
            }
        } else {
            HStack(spacing: 4) {
                WidgetCheckbox(item: item)
                Spacer(minLength: 4)
                if let minute = item.occurrence.timing.fixedMinute {
                    Text(TimeOfDayFormatter.string(minute: minute))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: Footer and messages

    @ViewBuilder
    private var footer: some View {
        if list.missedCount > 0 {
            Link(destination: DeepLink.missed.url) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle").accessibilityHidden(true)
                    Text("\(list.missedCount) missed today ›")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.red)
            }
        }
    }

    private func message(_ text: LocalizedStringKey, systemImage: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .widgetAccentable()
                .accessibilityHidden(true)
            Text(text).font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func title(of section: DaySection) -> String {
        section.part?.title ?? String(localized: "Anytime")
    }

    private func endDate(of section: DaySection) -> Date {
        DayKey(date, calendar: calendar).date(atMinute: section.window.upperBound, in: calendar)
    }
}
