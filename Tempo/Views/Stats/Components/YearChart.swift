import Charts
import Core
import SwiftUI

/// A bar for each month of the year. Tapping a month shows that month (SPEC F-14, D-083).
struct YearChart: View {
    let months: [MonthRate]
    let calendar: Calendar
    let onSelect: (MonthRate) -> Void

    var body: some View {
        Chart(months, id: \.month) { item in
            BarMark(
                x: .value("Month", label(item)),
                y: .value("Done", item.rate.percent ?? 0)
            )
            .foregroundStyle(item.rate.percent == nil ? Color.secondary.opacity(0.2) : RateColor.color(for: item.rate))
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
                                let month = months.first(where: { self.label($0) == label })
                            {
                                onSelect(month)
                            }
                        })
            }
        }
        .frame(height: 180)
        .accessibilityRepresentation {
            ForEach(months, id: \.month) { item in
                Button("\(fullName(item)): \(item.rate.percent.map { "\($0)%" } ?? "—")") { onSelect(item) }
            }
        }
    }

    /// "Jan", "Feb", …: unique within a year, unlike the one-letter names.
    private func label(_ item: MonthRate) -> String {
        calendar.shortStandaloneMonthSymbols[item.month - 1]
    }

    private func fullName(_ item: MonthRate) -> String {
        calendar.standaloneMonthSymbols[item.month - 1]
    }
}

#Preview {
    let months = (1...12).map {
        MonthRate(year: 2026, month: $0, rate: CompletionRate(done: $0, counted: $0 < 11 ? 12 : 0))
    }
    return YearChart(months: months, calendar: .autoupdatingCurrent) { _ in }.padding()
}
