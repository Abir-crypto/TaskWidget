import Core
import SwiftUI

/// This week's seven days for a habit: done, short, missed, upcoming or not scheduled (SPEC F-13).
struct WeekDots: View {
    let days: [(day: DayKey, result: DayResult)]
    let today: DayKey
    let calendar: Calendar

    var body: some View {
        HStack {
            ForEach(days, id: \.day) { item in
                VStack(spacing: 6) {
                    Text(item.day.weekday(in: calendar).initial(in: calendar))
                        .font(.caption2.weight(item.day == today ? .bold : .medium))
                        .foregroundStyle(item.day == today ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    DayResultMark(result: item.result)
                        .font(.title3)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(item.day.weekday(in: calendar).name(in: calendar))
                .accessibilityValue(item.result.label)
            }
        }
    }
}

#Preview {
    let calendar = Calendar.autoupdatingCurrent
    let today = DayKey(year: 2026, month: 10, day: 6)
    let results: [DayResult] = [.done, .missed, .upcoming, .notScheduled, .upcoming, .short, .notScheduled]
    return WeekDots(
        days: Array(zip(today.week(in: calendar), results)).map { (day: $0.0, result: $0.1) }, today: today,
        calendar: calendar
    )
    .padding()
}
