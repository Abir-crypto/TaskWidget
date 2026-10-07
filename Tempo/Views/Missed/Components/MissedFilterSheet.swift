import Core
import SwiftUI

/// Sort and filters for the Missed tab's Earlier section (SPEC F-08). Changes apply as they're made.
struct MissedFilterSheet: View {
    @Binding var filter: MissedFilter
    let tasks: [TaskValue]
    let today: DayKey
    let calendar: Calendar
    @Environment(\.dismiss) private var dismiss

    private enum RangeChoice: Hashable {
        case all
        case thisWeek
        case thisMonth
        case custom
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Sort") {
                    Picker("Order", selection: $filter.sort) {
                        Text("Newest first").tag(MissedSort.newestFirst)
                        Text("Oldest first").tag(MissedSort.oldestFirst)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Date") {
                    Picker("Range", selection: rangeChoice) {
                        Text("All").tag(RangeChoice.all)
                        Text("This week").tag(RangeChoice.thisWeek)
                        Text("This month").tag(RangeChoice.thisMonth)
                        Text("Custom").tag(RangeChoice.custom)
                    }
                    if case .custom(let first, let last) = filter.dateRange {
                        DatePicker(
                            "From", selection: customBinding(first: true, current: first, other: last),
                            in: ...yesterday, displayedComponents: .date)
                        DatePicker(
                            "To", selection: customBinding(first: false, current: last, other: first),
                            in: ...yesterday, displayedComponents: .date)
                    }
                }

                Section("Type") {
                    ForEach(TaskType.allCases, id: \.self) { type in
                        Toggle(type.title, isOn: membership(type, in: \.types))
                    }
                }

                Section("Part of the day") {
                    ForEach(MissedPartFilter.allCases, id: \.self) { part in
                        Toggle(title(for: part), isOn: membership(part, in: \.parts))
                    }
                }

                Section("Task") {
                    Picker("Task", selection: $filter.taskID) {
                        Text("Any task").tag(UUID?.none)
                        ForEach(tasks) { task in
                            Text(task.title).tag(UUID?.some(task.id))
                        }
                    }
                }

                if filter.isActive {
                    Section {
                        Button("Clear filters", role: .destructive) { filter = filter.cleared }
                    }
                }
            }
            .navigationTitle("Sort & filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var yesterday: Date {
        today.adding(days: -1, in: calendar).startDate(in: calendar)
    }

    private var rangeChoice: Binding<RangeChoice> {
        Binding(
            get: {
                switch filter.dateRange {
                case .all: .all
                case .thisWeek: .thisWeek
                case .thisMonth: .thisMonth
                case .custom: .custom
                }
            },
            set: { choice in
                switch choice {
                case .all: filter.dateRange = .all
                case .thisWeek: filter.dateRange = .thisWeek
                case .thisMonth: filter.dateRange = .thisMonth
                case .custom:
                    let last = today.adding(days: -1, in: calendar)
                    filter.dateRange = .custom(first: last.adding(days: -6, in: calendar), last: last)
                }
            })
    }

    private func customBinding(first isFirst: Bool, current: DayKey, other: DayKey) -> Binding<Date> {
        Binding(
            get: { current.startDate(in: calendar) },
            set: { date in
                let day = DayKey(date, calendar: calendar)
                filter.dateRange = isFirst ? .custom(first: day, last: other) : .custom(first: other, last: day)
            })
    }

    private func membership<Value: Hashable>(
        _ value: Value, in keyPath: WritableKeyPath<MissedFilter, Set<Value>>
    ) -> Binding<Bool> {
        Binding(
            get: { filter[keyPath: keyPath].contains(value) },
            set: { isOn in
                if isOn { filter[keyPath: keyPath].insert(value) } else { filter[keyPath: keyPath].remove(value) }
            })
    }

    private func title(for part: MissedPartFilter) -> String {
        switch part {
        case .morning: DayPart.morning.title
        case .noon: DayPart.noon.title
        case .evening: DayPart.evening.title
        case .night: DayPart.night.title
        case .anytime: String(localized: "Anytime")
        }
    }
}

#Preview {
    MissedFilterSheet(
        filter: .constant(MissedFilter(dateRange: .thisMonth, types: [.progress])), tasks: [],
        today: DayKey(year: 2026, month: 10, day: 6), calendar: .autoupdatingCurrent)
}
