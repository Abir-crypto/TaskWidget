import Core
import SwiftUI

/// Habit detail (SPEC F-13): the habit's schedule, this week, a month calendar, stats, streak, today's time
/// entries and recent missed days.
struct HabitDetailView: View {
    let dependencies: AppDependencies
    @State private var model: HabitDetailViewModel
    @Environment(NavigationRouter.self) private var router
    @Environment(TimerController.self) private var timer
    @Environment(\.dismiss) private var dismiss
    @Environment(\.missedStyle) private var missedStyle

    init(dependencies: AppDependencies, taskID: UUID) {
        self.dependencies = dependencies
        _model = State(
            initialValue: HabitDetailViewModel(tasks: dependencies.tasks, clock: dependencies.clock, taskID: taskID))
    }

    var body: some View {
        Group {
            if let task = model.task {
                content(task)
            } else if model.isLoaded {
                ContentUnavailableView("This habit no longer exists", systemImage: "trash")
            } else {
                ProgressView()
            }
        }
        .navigationTitle(model.task?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if model.task != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { router.openEditor(.edit(model.taskID)) }
                }
            }
        }
        .task(id: dependencies.refresh.revision) { model.load() }
        .confirmationDialog(
            "End this habit?", isPresented: $model.isConfirmingEnd, titleVisibility: .visible
        ) {
            Button("End habit") { model.endHabit() }
            Button("Cancel", role: .cancel) {}
        } message: {
            if timer.isTiming(model.taskID) {
                Text(
                    "It moves to History with its stats, and you can start it again later. Its running timer will be discarded."
                )
            } else {
                Text("It moves to History with its stats, and you can start it again later.")
            }
        }
        .alert(
            "Couldn't change the habit",
            isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } }),
            presenting: model.errorMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .alert("Started again", isPresented: $model.restarted) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("“\(model.task?.title ?? "")” starts again today. You'll find it in Tasks.")
        }
    }

    private func content(_ task: TaskValue) -> some View {
        List {
            header(task)
            actions(task)
            if model.hasData {
                weekSection
                monthSection
                statsSection(task)
                streakSection
            } else {
                Section {
                    ContentUnavailableView(
                        "No data yet", systemImage: "chart.bar",
                        description: Text("No data yet. Check back after its first day."))
                }
            }
            if task.type == .duration {
                entriesSection
            }
            if model.hasData {
                missedSection
            }
        }
        .readableScrollContent()
    }

    // MARK: Header and buttons

    private func header(_ task: TaskValue) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Label(model.typeTitle, systemImage: task.type.systemImage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.tint)
                Text(task.title)
                    .font(.title2.weight(.semibold))
                Text(model.scheduleSummary)
                    .foregroundStyle(.secondary)
                // One text, so it wraps as a sentence at large text sizes.
                Text([model.targetText, model.lengthText].compactMap { $0 }.joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel([model.targetText, model.lengthText].compactMap { $0 }.joined(separator: ", "))
                if let notes = task.notes {
                    Text(notes)
                        .padding(.top, 2)
                }
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private func actions(_ task: TaskValue) -> some View {
        Section {
            if task.type == .duration, model.canLogTime, timer.active == nil {
                Button {
                    timer.startHabit(task.id)
                } label: {
                    Label("Start timer", systemImage: "play.fill")
                }
            }
            if task.type == .duration, model.canLogTime {
                Button {
                    router.logTime = LogTimeRequest(taskID: task.id)
                } label: {
                    Label("Log time", systemImage: "plus.circle")
                }
            }
            if model.isEnded {
                Button {
                    model.startAgain()
                } label: {
                    Label("Start again", systemImage: "arrow.counterclockwise")
                }
            } else {
                Button {
                    model.isConfirmingEnd = true
                } label: {
                    Label("End habit", systemImage: "flag.checkered")
                }
            }
        }
    }

    // MARK: Week, month, stats, streak

    private var weekSection: some View {
        Section("This week") {
            WeekDots(days: model.week, today: model.today, calendar: model.calendar)
                .padding(.vertical, 4)
        }
    }

    private var monthSection: some View {
        Section {
            MonthCalendar(
                month: model.month, results: model.monthDays, today: model.today, calendar: model.calendar,
                canGoBack: model.canShowPreviousMonth, canGoForward: model.canShowNextMonth,
                onBack: { model.showPreviousMonth() }, onForward: { model.showNextMonth() }
            )
            .padding(.vertical, 4)
        } footer: {
            HStack(spacing: 12) {
                legend(.done)
                legend(.short)
                legend(.missed)
                legend(.upcoming)
            }
        }
    }

    private func legend(_ result: DayResult) -> some View {
        HStack(spacing: 4) {
            DayResultMark(result: result).accessibilityHidden(true)
            Text(result.label(missedStyle))
        }
    }

    private func statsSection(_ task: TaskValue) -> some View {
        Section("Stats") {
            ForEach(model.stats) { stat in
                LabeledContent {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(stat.rate.percent.map { "\($0)%" } ?? "—")
                            .monospacedDigit()
                        if let minutes = stat.minutes {
                            Text(timeText(minutes: minutes, goal: stat.weeklyGoal))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                } label: {
                    Text(rangeTitle(stat.kind))
                }
            }
        }
    }

    private func timeText(minutes: Int, goal: Int?) -> String {
        let total = DurationFormatter.short(minutes: minutes)
        guard let goal else { return String(localized: "\(total) total") }
        return String(localized: "\(total) of \(DurationFormatter.short(minutes: goal))")
    }

    private func rangeTitle(_ kind: StatsRangeKind) -> LocalizedStringKey {
        switch kind {
        case .week: "This week"
        case .month: "This month"
        case .year: "This year"
        }
    }

    private var streakSection: some View {
        Section("Streak") {
            LabeledContent("Current") { Text("^[\(model.streak.current) day](inflect: true)") }
            LabeledContent("Best") { Text("^[\(model.streak.best) day](inflect: true)") }
        }
    }

    // MARK: Entries and missed days

    @ViewBuilder
    private var entriesSection: some View {
        Section("Today's time") {
            if model.todaysEntries.isEmpty {
                Text("No time logged today").foregroundStyle(.secondary)
            }
            ForEach(model.todaysEntries) { entry in
                entryRow(entry)
            }
        }
        // Yesterday's entries can still be deleted until Afternoon starts (SPEC F-13, §5.11).
        if !model.yesterdaysEntries.isEmpty {
            Section("Yesterday's time") {
                ForEach(model.yesterdaysEntries) { entry in
                    entryRow(entry)
                }
            }
        }
    }

    private func entryRow(_ entry: TimeEntryValue) -> some View {
        LabeledContent {
            Text("\(entry.seconds / 60) min").monospacedDigit()
        } label: {
            Label(
                entry.source == .timer ? "Timer" : "Logged by hand",
                systemImage: entry.source == .timer ? "timer" : "hand.tap")
        }
        .swipeActions {
            if model.canDelete(entry) {
                Button("Delete", role: .destructive) { model.deleteEntry(entry) }
            }
        }
    }

    private var missedSection: some View {
        Section {
            if model.recentMissed.isEmpty {
                Text(missedStyle.noRecentDays).foregroundStyle(.secondary)
            }
            ForEach(model.recentMissed) { item in
                LabeledContent {
                    if let target = item.targetMinutes, item.status == .short {
                        Text(DurationFormatter.progress(minutes: item.minutes, target: target))
                    } else {
                        StatusLabel(status: .missed)
                    }
                } label: {
                    Text(DayTitleFormatter.title(for: item.day, today: model.today, calendar: model.calendar))
                }
            }
        } header: {
            HStack {
                Text(missedStyle.recentDaysTitle)
                Spacer()
                // A 44-point target inside the header's line height: the label grows and the button gives it back.
                Button {
                    router.showMissed(for: model.taskID)
                } label: {
                    Text("See all").padding(.vertical, 13).contentShape(Rectangle())
                }
                .padding(.vertical, -13)
                .font(.footnote)
                .textCase(nil)
            }
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview(hour: 13, sample: true)
    let id = (try? dependencies.tasks.engine().tasks.first { $0.type == .duration }?.id) ?? UUID()
    return NavigationStack {
        HabitDetailView(dependencies: dependencies, taskID: id)
    }
    .previewEnvironment(dependencies)
}
