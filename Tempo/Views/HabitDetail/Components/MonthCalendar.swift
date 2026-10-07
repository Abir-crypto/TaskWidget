import Core
import SwiftUI

/// A month grid with each scheduled day marked by its result, and arrows between months (SPEC F-13).
struct MonthCalendar: View {
    let month: DayKey
    let results: [DayKey: DayResult]
    let today: DayKey
    let calendar: Calendar
    let canGoBack: Bool
    let canGoForward: Bool
    let onBack: () -> Void
    let onForward: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: onBack) { Image(systemName: "chevron.left") }
                    .disabled(!canGoBack)
                    .accessibilityLabel("Previous month")
                Spacer()
                Text(month.startDate(in: calendar).formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                Spacer()
                Button(action: onForward) { Image(systemName: "chevron.right") }
                    .disabled(!canGoForward)
                    .accessibilityLabel("Next month")
            }
            .buttonStyle(.borderless)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Weekday.ordered(firstWeekday: calendar.firstWeekday), id: \.self) { weekday in
                    Text(weekday.initial(in: calendar))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                ForEach(0..<leadingBlanks, id: \.self) { _ in
                    Color.clear.frame(height: 32).accessibilityHidden(true)
                }
                ForEach(days, id: \.self) { day in
                    dayCell(day)
                }
            }
        }
    }

    private var days: [DayKey] {
        StatsRange.containing(month, kind: .month, calendar: calendar).days(in: calendar)
    }

    private var leadingBlanks: Int {
        (month.weekday(in: calendar).calendarWeekday - calendar.firstWeekday + 7) % 7
    }

    private func dayCell(_ day: DayKey) -> some View {
        let result = results[day] ?? .notScheduled
        return Text(String(day.day))
            .font(.footnote.weight(day == today ? .bold : .regular))
            .monospacedDigit()
            .frame(maxWidth: .infinity, minHeight: 32)
            .background(background(for: result), in: Circle())
            .foregroundStyle(result == .done || result == .missed ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .overlay {
                if result == .upcoming { Circle().stroke(.secondary, lineWidth: 1) }
                if day == today { Circle().stroke(.tint, lineWidth: 2) }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(day.startDate(in: calendar).formatted(.dateTime.weekday(.wide).day().month(.wide)))
            .accessibilityValue(result.label)
    }

    private func background(for result: DayResult) -> AnyShapeStyle {
        switch result {
        case .done: AnyShapeStyle(Color.green)
        case .missed: AnyShapeStyle(Color.red)
        case .short: AnyShapeStyle(Color.orange.opacity(0.35))
        case .upcoming, .notScheduled: AnyShapeStyle(Color.clear)
        }
    }
}

#Preview {
    let calendar = Calendar.autoupdatingCurrent
    let month = DayKey(year: 2026, month: 10, day: 1)
    var results: [DayKey: DayResult] = [:]
    for day in 1...5 { results[DayKey(year: 2026, month: 10, day: day)] = day == 3 ? .missed : .done }
    results[DayKey(year: 2026, month: 10, day: 6)] = .upcoming
    return MonthCalendar(
        month: month, results: results, today: DayKey(year: 2026, month: 10, day: 6), calendar: calendar,
        canGoBack: true, canGoForward: false, onBack: {}, onForward: {}
    )
    .padding()
}
