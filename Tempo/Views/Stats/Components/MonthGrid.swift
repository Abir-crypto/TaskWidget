import Core
import SwiftUI

/// A calendar of the month, each day colored by the habits' completion. Tapping a day opens it in Today
/// (SPEC F-14).
struct MonthGrid: View {
    let days: [DayRate]
    let today: DayKey
    let calendar: Calendar
    let onSelect: (DayKey) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Weekday.ordered(firstWeekday: calendar.firstWeekday), id: \.self) { weekday in
                Text(weekday.initial(in: calendar))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            ForEach(0..<leadingBlanks, id: \.self) { _ in
                Color.clear.frame(height: 34).accessibilityHidden(true)
            }
            ForEach(days, id: \.day) { item in
                Button {
                    onSelect(item.day)
                } label: {
                    Text(String(item.day.day))
                        .font(.footnote.weight(item.day == today ? .bold : .regular))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background(RateColor.color(for: item.rate), in: RoundedRectangle(cornerRadius: 6))
                        .overlay {
                            if item.day == today { RoundedRectangle(cornerRadius: 6).stroke(.tint, lineWidth: 2) }
                        }
                        .foregroundStyle(item.day > today ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.primary))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    item.day.startDate(in: calendar).formatted(.dateTime.weekday(.wide).day().month(.wide))
                )
                .accessibilityValue(item.rate.percent.map { "\($0)%" } ?? String(localized: "No habit days"))
                .accessibilityIdentifier("stats-day-\(item.day.rawValue)")
            }
        }
    }

    private var leadingBlanks: Int {
        guard let first = days.first?.day else { return 0 }
        return (first.weekday(in: calendar).calendarWeekday - calendar.firstWeekday + 7) % 7
    }
}

#Preview {
    let calendar = Calendar.autoupdatingCurrent
    let days = (1...31).map {
        DayRate(
            day: DayKey(year: 2026, month: 10, day: $0), rate: CompletionRate(done: $0 % 3, counted: $0 < 7 ? 2 : 0))
    }
    return MonthGrid(days: days, today: DayKey(year: 2026, month: 10, day: 6), calendar: calendar) { _ in }.padding()
}
