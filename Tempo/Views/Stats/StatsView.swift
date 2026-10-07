import Core
import SwiftUI

/// The Stats tab (SPEC F-14): a week, month or year, with overview, chart, time, parts of the day, streaks
/// and habits.
struct StatsView: View {
    let dependencies: AppDependencies
    @Bindable var router: NavigationRouter
    @State private var model: StatsViewModel

    init(dependencies: AppDependencies, router: NavigationRouter) {
        self.dependencies = dependencies
        self.router = router
        _model = State(initialValue: StatsViewModel(manager: dependencies.stats, clock: dependencies.clock))
    }

    var body: some View {
        NavigationStack {
            Group {
                if let stats = model.stats {
                    if stats.hasHabits {
                        cards(stats)
                    } else {
                        ContentUnavailableView {
                            Label("Add a habit to see your stats", systemImage: "chart.bar")
                        } actions: {
                            Button("Add a habit") { router.openEditor(.new(type: .progress)) }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Stats")
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .habit(let id): HabitDetailView(dependencies: dependencies, taskID: id)
                }
            }
        }
        .safeAreaInset(edge: .bottom) { TimerBar() }
        .task(id: dependencies.refresh.revision) { model.load() }
    }

    private func cards(_ stats: StatsSnapshot) -> some View {
        List {
            Section {
                rangePicker
            }
            overview(stats)
            chart(stats)
            if !stats.time.isEmpty {
                time(stats)
            }
            parts(stats)
            streaks(stats)
            habits(stats)
        }
    }

    // MARK: Range

    private var rangePicker: some View {
        VStack(spacing: 12) {
            Picker("Range", selection: $model.kind) {
                Text("Week").tag(StatsRangeKind.week)
                Text("Month").tag(StatsRangeKind.month)
                Text("Year").tag(StatsRangeKind.year)
            }
            .pickerStyle(.segmented)
            HStack {
                Button {
                    model.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(!model.canGoBack)
                .accessibilityLabel("Previous")
                Spacer()
                Text(model.rangeTitle).font(.headline)
                Spacer()
                Button {
                    model.goForward()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!model.canGoForward)
                .accessibilityLabel("Next")
            }
            .buttonStyle(.borderless)
        }
    }

    // MARK: 1. Overview

    private func overview(_ stats: StatsSnapshot) -> some View {
        Section("Overview") {
            VStack(alignment: .leading, spacing: 4) {
                Text(stats.rate.percent.map { "\($0)%" } ?? "—")
                    .font(.largeTitle.weight(.bold))
                    .monospacedDigit()
                if let change = model.changeText {
                    Text(change).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            LabeledContent("Habit days done", value: String(localized: "\(stats.rate.done) of \(stats.rate.counted)"))
            LabeledContent("One-time tasks completed", value: String(stats.oneTimeCompleted))
            LabeledContent("Time logged", value: DurationFormatter.short(minutes: stats.totalMinutes))
        }
    }

    // MARK: 2. Completion chart

    @ViewBuilder
    private func chart(_ stats: StatsSnapshot) -> some View {
        Section {
            switch stats.range.kind {
            case .week:
                WeekChart(days: stats.days, calendar: model.calendar) { router.showDay($0) }
            case .month:
                MonthGrid(days: stats.days, today: model.today, calendar: model.calendar) { router.showDay($0) }
            case .year:
                YearChart(months: stats.months, calendar: model.calendar) { model.showMonth($0) }
            }
        } header: {
            Text("Completion")
        } footer: {
            Text(stats.range.kind == .year ? "Tap a month to see it." : "Tap a day to open it in Today.")
        }
    }

    // MARK: 3. Time

    private func time(_ stats: StatsSnapshot) -> some View {
        Section("Time") {
            ForEach(stats.time, id: \.task.id) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.task.title)
                        Spacer()
                        Text(
                            "\(DurationFormatter.short(minutes: item.progress.minutes)) of \(DurationFormatter.short(minutes: item.progress.goal))"
                        )
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    }
                    ProgressView(
                        value: Double(min(item.progress.minutes, max(item.progress.goal, 1))),
                        total: Double(max(item.progress.goal, 1)))
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    // MARK: 4. Parts of the day

    private func parts(_ stats: StatsSnapshot) -> some View {
        Section {
            ForEach(stats.parts, id: \.part) { item in
                LabeledContent(partTitle(item.part), value: item.rate.percent.map { "\($0)%" } ?? "—")
            }
        } header: {
            Text("Parts of the day")
        } footer: {
            if let worst = stats.mostMissed {
                Text("Most missed: \(partTitle(worst))")
            }
        }
    }

    private func partTitle(_ part: MissedPartFilter) -> String {
        switch part {
        case .morning: DayPart.morning.title
        case .noon: DayPart.noon.title
        case .evening: DayPart.evening.title
        case .night: DayPart.night.title
        case .anytime: String(localized: "Anytime")
        }
    }

    // MARK: 5. Streaks

    private func streaks(_ stats: StatsSnapshot) -> some View {
        Section("Streaks") {
            ForEach(stats.streaks, id: \.task.id) { item in
                LabeledContent(item.task.title) {
                    Text("Current \(item.streak.current) · Best \(item.streak.best)")
                        .monospacedDigit()
                }
            }
        }
    }

    // MARK: 6. Habits

    private func habits(_ stats: StatsSnapshot) -> some View {
        Section("Habits") {
            ForEach(stats.habits, id: \.task.id) { item in
                NavigationLink(value: Route.habit(item.task.id)) {
                    LabeledContent(item.task.title, value: item.rate.percent.map { "\($0)%" } ?? "—")
                }
            }
        }
    }
}

#Preview("Sample") {
    StatsView(dependencies: .preview(hour: 13, sample: true), router: NavigationRouter())
        .environment(NavigationRouter())
}

#Preview("Empty") {
    StatsView(dependencies: .preview(), router: NavigationRouter())
}
