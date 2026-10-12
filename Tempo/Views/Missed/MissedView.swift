import Core
import SwiftUI

/// The Missed tab (SPEC F-08): today's missed tasks, which can still change, and earlier ones.
struct MissedView: View {
    let dependencies: AppDependencies
    @Bindable var router: NavigationRouter
    @State private var model: MissedViewModel
    @State private var isFiltering = false
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.missedStyle) private var missedStyle

    init(dependencies: AppDependencies, router: NavigationRouter) {
        self.dependencies = dependencies
        self.router = router
        _model = State(initialValue: MissedViewModel(tasks: dependencies.tasks, clock: dependencies.clock))
    }

    var body: some View {
        NavigationStack {
            TimelineView(.everyMinute) { context in
                list
                    // Yesterday's rows move to Earlier when the correction window closes (SPEC §5.11).
                    .task(id: context.date) { if model.needsReload { model.load() } }
            }
            .navigationTitle(missedStyle.statusTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isFiltering = true
                    } label: {
                        Image(
                            systemName: model.filter.isActive
                                ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Sort and filter")
                    .accessibilityValue(model.filter.isActive ? Text("Filters on") : Text("No filters"))
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .habit(let id): HabitDetailView(dependencies: dependencies, taskID: id)
                }
            }
            .sheet(isPresented: $isFiltering) {
                MissedFilterSheet(
                    filter: $model.filter, tasks: model.filterableTasks, today: model.today, calendar: model.calendar)
            }
        }
        .safeAreaInset(edge: .bottom) { TimerBar() }
        // A light tap for each task marked done (ios.md §12).
        .sensoryFeedback(.success, trigger: model.completions)
        .task(id: dependencies.refresh.revision) { model.load() }
        .onChange(of: router.missedTaskFilter, initial: true) { _, taskID in
            guard let taskID else { return }
            model.showOnly(taskID: taskID)
            router.missedTaskFilter = nil
        }
        .onChange(of: router.missedHighlight, initial: true) { _, ids in
            // "Review missed tasks" from the popup highlights its tasks until the tab is left.
            guard !ids.isEmpty else { return }
            model.highlighted = ids
            router.missedHighlight = []
        }
        .onChange(of: router.selectedTab) { _, tab in
            if tab != .missed { model.highlighted = [] }
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

    private var list: some View {
        List {
            todaySection
            earlierSection
        }
        .readableScrollContent()
    }

    // MARK: Today

    /// Today's missed tasks and, while it can still be corrected, yesterday's under their own subheading
    /// (SPEC F-08, §5.11).
    private var todaySection: some View {
        Section {
            if model.isLoaded, model.todayItems.isEmpty {
                Text(missedStyle.todayEmpty).foregroundStyle(.secondary)
            }
            ForEach(model.todayItems) { item in
                changeableRow(item)
            }
            if !model.yesterdayItems.isEmpty {
                Text("Yesterday")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
                ForEach(model.yesterdayItems) { item in
                    changeableRow(item)
                }
            }
        } header: {
            Text("Today")
        } footer: {
            if !model.todayItems.isEmpty || !model.yesterdayItems.isEmpty {
                Text("You can still change these")
            }
        }
    }

    private func changeableRow(_ item: MissedItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            MissedRow(item: item, dueText: model.dueText(item))
            actions(for: item)
        }
        .listRowBackground(model.highlighted.contains(item.id) ? Rectangle().fill(.tint.opacity(0.15)) : nil)
    }

    /// Side by side, or one under another at accessibility text sizes (SPEC T-31).
    private func actions(for item: MissedItem) -> some View {
        let layout =
            typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            if model.canMarkDone(item) {
                Button("Mark done") { model.markDone(item) }
            }
            if model.canLogTime(item) {
                Button("Log time") { router.logTime = LogTimeRequest(taskID: item.occurrence.task.id, day: item.day) }
            }
            if model.canMove(item) {
                Button("Move to tomorrow") { model.moveToTomorrow(item) }
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .padding(.leading, 36)
    }

    // MARK: Earlier

    private var earlierSection: some View {
        Section {
            if model.isLoaded, !model.hasEarlier {
                Text(missedStyle.earlierEmpty).foregroundStyle(.secondary)
            } else if model.isLoaded, model.earlierCount == 0 {
                VStack(spacing: 8) {
                    Text(missedStyle.filtersEmpty).foregroundStyle(.secondary)
                    Button("Clear filters") { model.clearFilters() }
                        .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            ForEach(model.earlierGroups) { group in
                Text(group.title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
                ForEach(group.items) { item in
                    MissedRow(item: item, dueText: model.dueText(item))
                }
            }
        } header: {
            HStack {
                Text("Earlier")
                Spacer()
                if model.hasEarlier {
                    Text(missedStyle.count(model.earlierCount)).textCase(nil)
                }
            }
        } footer: {
            if model.filter.isActive, model.earlierCount > 0 {
                Button("Clear filters") { model.clearFilters() }
                    .font(.footnote)
            }
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview(hour: 13, sample: true)
    return MissedView(dependencies: dependencies, router: NavigationRouter()).previewEnvironment(dependencies)
}
