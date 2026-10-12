import Core
import SwiftUI

/// The Today tab (SPEC F-10): the day strip, then Morning, Noon, Evening, Night and Anytime.
struct TodayView: View {
    let dependencies: AppDependencies
    @Bindable var router: NavigationRouter
    @State private var model: TodayViewModel
    @Environment(TimerController.self) private var timer

    init(dependencies: AppDependencies, router: NavigationRouter) {
        self.dependencies = dependencies
        self.router = router
        _model = State(initialValue: TodayViewModel(tasks: dependencies.tasks, clock: dependencies.clock))
    }

    var body: some View {
        NavigationStack {
            // Statuses and "ends in …" change with the clock, so the screen is rebuilt every minute.
            TimelineView(.everyMinute) { _ in
                content(now: dependencies.clock.now)
            }
            .navigationTitle(model.title)
            .toolbar { toolbar }
            .navigationDestination(isPresented: $router.isSettingsPresented) {
                SettingsView(dependencies: dependencies)
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .habit(let id): HabitDetailView(dependencies: dependencies, taskID: id)
                }
            }
            .floatingAddButton { router.openEditor(.new(day: max(model.selectedDay, model.today))) }
        }
        .safeAreaInset(edge: .bottom) { TimerBar() }
        // A light tap for each completion and each change of day (ios.md §12).
        .sensoryFeedback(.success, trigger: model.completions)
        .sensoryFeedback(.selection, trigger: model.selectedDay)
        .task(id: dependencies.refresh.revision) { model.load() }
        .onChange(of: router.todayFocus, initial: true) { _, focus in
            guard let focus else { return }
            model.load()
            model.focus(focus)
            router.todayFocus = nil
        }
        .confirmationDialog(
            deleteTitle,
            isPresented: Binding(get: { model.pendingDelete != nil }, set: { if !$0 { model.pendingDelete = nil } }),
            titleVisibility: .visible,
            presenting: model.pendingDelete
        ) { item in
            deleteButtons(for: item)
        } message: { item in
            if item.task.type == .oneTime {
                Text("This can't be undone.")
            } else if timer.isTiming(item.task.id) {
                Text(
                    "End habit keeps its history and stats. Delete with history removes them for good. Its running timer will be discarded."
                )
            } else {
                Text("End habit keeps its history and stats. Delete with history removes them for good.")
            }
        }
        .alert(
            "Couldn't change the task",
            isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } }),
            presenting: model.errorMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    // MARK: Layout

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if !model.isShowingToday {
            ToolbarItem(placement: .topBarLeading) {
                Button("Today") { model.goToToday() }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                router.isSettingsPresented = true
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Settings")
        }
    }

    private func content(now: Date) -> some View {
        VStack(spacing: 0) {
            DayStrip(
                days: model.week(at: now), selected: model.selectedDay, calendar: model.calendar,
                onSelect: { model.select($0) }, onSwipe: { model.moveWeek(by: $0) }
            )
            .readableWidth()
            // Yesterday can still be corrected until Afternoon starts (SPEC F-10, §5.11).
            if let minute = model.correctionClosingMinute(at: now) {
                Text("You can still change yesterday until \(TimeOfDayFormatter.string(minute: minute))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .readableWidth()
            }
            Divider()
            if let plan = model.plan(at: now) {
                if plan.isEmpty {
                    emptyDay
                } else {
                    list(plan, now: now)
                }
            } else {
                Spacer()
                ProgressView()
                Spacer()
            }
        }
    }

    private func list(_ plan: DayPlan, now: Date) -> some View {
        ScrollViewReader { proxy in
            List {
                ForEach(plan.sections) { section in
                    sectionView(section, now: now)
                        .id(section.id)
                }
            }
            .readableScrollContent()
            .onChange(of: model.scrollTarget, initial: true) { _, target in
                guard let target else { return }
                withAnimation { proxy.scrollTo(target, anchor: .top) }
                model.scrollTarget = nil
            }
        }
    }

    @ViewBuilder
    private func sectionView(_ section: DaySection, now: Date) -> some View {
        if section.phase == .ended, !section.items.isEmpty, let part = section.part {
            // An ended part of today folds into one line; tapping it shows its tasks.
            let collapsed = model.isCollapsed(section)
            Section {
                CollapsedPartRow(section: section, isExpanded: !collapsed) {
                    withAnimation { model.toggleExpanded(part) }
                }
                if !collapsed {
                    ForEach(section.items) { row($0) }
                }
            }
        } else {
            Section {
                if section.items.isEmpty {
                    Text(emptyPartText(section))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                ForEach(section.items) { row($0) }
            } header: {
                PartHeader(section: section, minutesLeft: minutesLeft(in: section, now: now))
            }
        }
    }

    private func minutesLeft(in section: DaySection, now: Date) -> Int? {
        guard section.phase == .current else { return nil }
        return section.window.upperBound - LocalTime(now, calendar: model.calendar).minute
    }

    // MARK: Rows

    @ViewBuilder
    private func row(_ item: DayItem) -> some View {
        Group {
            if item.task.type.isHabit {
                NavigationLink(value: Route.habit(item.task.id)) { rowContent(item) }
            } else {
                Button {
                    router.openEditor(.edit(item.task.id))
                } label: {
                    rowContent(item).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .id(item.id)
        .swipeActions(edge: .leading, allowsFullSwipe: true) { leadingActions(item) }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) { trailingActions(item) }
    }

    @ViewBuilder
    private func rowContent(_ item: DayItem) -> some View {
        if item.task.type == .duration {
            DurationRow(
                item: item,
                onStart: timer.active == nil && model.canStartTimer(item) ? { timer.startHabit(item.task.id) } : nil)
        } else {
            TaskRow(item: item, canComplete: model.canComplete(item)) { model.toggleCompletion(item) }
        }
    }

    @ViewBuilder
    private func leadingActions(_ item: DayItem) -> some View {
        if model.canComplete(item) {
            Button(item.status == .done ? "Undo" : "Done") { model.toggleCompletion(item) }
                .tint(item.status == .done ? .gray : .green)
        }
        if model.canLogTime(item) {
            Button("Log time") { router.logTime = LogTimeRequest(taskID: item.task.id, day: item.occurrence.day) }
                .tint(.blue)
        }
    }

    @ViewBuilder
    private func trailingActions(_ item: DayItem) -> some View {
        if model.canEditOrDelete(item) {
            Button("Delete") { model.requestDelete(item) }
                .tint(.red)
            Button("Edit") { router.openEditor(.edit(item.task.id)) }
                .tint(.gray)
        }
        if model.canMove(item) {
            Button(model.isShowingToday ? "Move to tomorrow" : "Move to next day") { model.moveToNextDay(item) }
                .tint(.orange)
        }
    }

    // MARK: Delete

    private var deleteTitle: LocalizedStringKey {
        model.pendingDelete?.task.type == .oneTime ? "Delete this task?" : "End or delete this habit?"
    }

    @ViewBuilder
    private func deleteButtons(for item: DayItem) -> some View {
        if item.task.type == .oneTime {
            Button("Delete task", role: .destructive) { model.deleteOneTime(item) }
        } else {
            Button("End habit") { model.endHabit(item) }
            Button("Delete with history", role: .destructive) { model.deleteWithHistory(item) }
        }
        Button("Cancel", role: .cancel) {}
    }

    // MARK: Empty states (SPEC F-24)

    @ViewBuilder
    private var emptyDay: some View {
        let date = DayTitleFormatter.shortDate(model.selectedDay, calendar: model.calendar)
        if model.isShowingToday {
            ContentUnavailableView {
                Label("No tasks today", systemImage: "sun.max")
            } actions: {
                Button("Add a task") { router.openEditor(.new(day: model.today)) }
                    .buttonStyle(.borderedProminent)
            }
        } else if model.isPastDay {
            ContentUnavailableView("Nothing was planned for \(date)", systemImage: "calendar")
        } else {
            ContentUnavailableView {
                Label("Nothing planned for \(date)", systemImage: "calendar")
            } actions: {
                Button("Add a task") { router.openEditor(.new(day: model.selectedDay)) }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private func emptyPartText(_ section: DaySection) -> LocalizedStringKey {
        let today = model.isShowingToday
        switch section.part {
        case .morning: return today ? "Nothing this morning" : "Nothing in the morning"
        case .noon: return today ? "Nothing this afternoon" : "Nothing in the afternoon"
        case .evening: return today ? "Nothing this evening" : "Nothing in the evening"
        case .night: return today ? "Nothing tonight" : "Nothing at night"
        case nil: return "No anytime tasks"
        }
    }
}

#Preview("Today") {
    let dependencies = AppDependencies.preview(hour: 13, sample: true)
    return TodayView(dependencies: dependencies, router: NavigationRouter()).previewEnvironment(dependencies)
}

#Preview("Empty") {
    let dependencies = AppDependencies.preview()
    return TodayView(dependencies: dependencies, router: NavigationRouter()).previewEnvironment(dependencies)
}
