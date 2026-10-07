import Charts
import Core
import SwiftUI

/// A bar for each day of the week: the habits' completion that day. Tapping a day opens it in Today (SPEC F-14).
struct WeekChart: View {
    let days: [DayRate]
    let calendar: Calendar
    let onSelect: (DayKey) -> Void

    var body: some View {
        Chart(days, id: \.day) { item in
            BarMark(
                x: .value("Day", label(item.day)),
                y: .value("Done", item.rate.percent ?? 0)
            )
            .foregroundStyle(
                RateColor.color(for: item.rate) == .clear
                    ? Color.secondary.opacity(0.2) : RateColor.color(for: item.rate))
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(values: [0, 50, 100]) { value in
                AxisGridLine()
                AxisValueLabel { Text("\(value.as(Int.self) ?? 0)%") }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture().onEnded { tap in
                            guard let plot = proxy.plotFrame else { return }
                            let x = tap.location.x - geometry[plot].origin.x
                            if let label: String = proxy.value(atX: x),
                                let day = days.first(where: { self.label($0.day) == label })?.day
                            {
                                onSelect(day)
                            }
                        })
            }
        }
        .frame(height: 180)
        .accessibilityRepresentation {
            ForEach(days, id: \.day) { item in
                Button(accessibilityLabel(item)) { onSelect(item.day) }
            }
        }
    }

    private func label(_ day: DayKey) -> String {
        "\(day.weekday(in: calendar).initial(in: calendar)) \(day.day)"
    }

    private func accessibilityLabel(_ item: DayRate) -> String {
        let date = item.day.startDate(in: calendar).formatted(.dateTime.weekday(.wide).day().month(.wide))
        guard let percent = item.rate.percent else { return "\(date): —" }
        return "\(date): \(percent)%"
    }
}

#Preview {
    let calendar = Calendar.autoupdatingCurrent
    let days = DayKey(year: 2026, month: 10, day: 6).week(in: calendar).enumerated().map {
        DayRate(day: $0.element, rate: CompletionRate(done: $0.offset % 3, counted: $0.offset < 4 ? 2 : 0))
    }
    return WeekChart(days: days, calendar: calendar) { _ in }.padding()
}
