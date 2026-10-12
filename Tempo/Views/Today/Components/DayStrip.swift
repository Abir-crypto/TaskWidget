import Core
import SwiftUI

/// The seven days of the week under the title. Tap a day to select it; swipe to move by a week (SPEC F-10).
struct DayStrip: View {
    let days: [DayStripDay]
    let selected: DayKey
    let calendar: Calendar
    let onSelect: (DayKey) -> Void
    let onSwipe: (Int) -> Void
    @Environment(\.missedStyle) private var missedStyle

    var body: some View {
        HStack(spacing: 4) {
            ForEach(days) { day in
                dayButton(day)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    onSwipe(value.translation.width < 0 ? 1 : -1)
                }
        )
        // Seven days must fit across, so the strip stops growing at the largest standard text size; at accessibility
        // sizes a long press shows the day in the Large Content Viewer (D-097).
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: Text("Next week")) { onSwipe(1) }
        .accessibilityAction(named: Text("Previous week")) { onSwipe(-1) }
    }

    private func dayButton(_ day: DayStripDay) -> some View {
        let isSelected = day.day == selected
        let date = day.day.startDate(in: calendar)
        return Button {
            onSelect(day.day)
        } label: {
            VStack(spacing: 4) {
                Text(day.day.weekday(in: calendar).initial(in: calendar))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(String(day.day.day))
                    .font(.callout.weight(isSelected || day.isToday ? .bold : .regular))
                    .monospacedDigit()
                    .frame(width: 34, height: 34)
                    .foregroundStyle(numberStyle(for: day, isSelected: isSelected))
                    .background {
                        if isSelected {
                            Circle().fill(day.isToday ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.primary))
                        }
                    }
                // The red dot is Strict only; Gentle shows the usual dot (SPEC F-30).
                Circle()
                    .fill(
                        day.dot == .missed && missedStyle == .strict ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary)
                    )
                    .frame(width: 5, height: 5)
                    .opacity(day.dot == .none ? 0 : 1)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityShowsLargeContentViewer {
            Text(date.formatted(.dateTime.weekday(.abbreviated).day()))
        }
        .accessibilityLabel(date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
        .accessibilityValue(accessibilityValue(for: day))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("day-\(day.day.rawValue)")
    }

    private func numberStyle(for day: DayStripDay, isSelected: Bool) -> AnyShapeStyle {
        if isSelected { return AnyShapeStyle(Color(uiColor: .systemBackground)) }
        return day.isToday ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.primary)
    }

    private func accessibilityValue(for day: DayStripDay) -> String {
        switch day.dot {
        case .none: String(localized: "No tasks")
        case .tasks: String(localized: "Has tasks")
        case .missed: missedStyle.dayHasMissed
        }
    }
}

#Preview {
    let calendar = Calendar.autoupdatingCurrent
    let today = DayKey(year: 2026, month: 10, day: 6)
    let days = today.week(in: calendar).map {
        DayStripDay(day: $0, dot: $0 < today ? .missed : ($0 == today ? .tasks : .none), isToday: $0 == today)
    }
    return DayStrip(days: days, selected: today, calendar: calendar, onSelect: { _ in }, onSwipe: { _ in })
}
