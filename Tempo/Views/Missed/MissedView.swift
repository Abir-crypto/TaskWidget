import Core
import SwiftUI

/// The Missed tab (SPEC F-08): today's missed tasks, which can still change, and earlier ones.
struct MissedView: View {
    let dependencies: AppDependencies
    @Bindable var router: NavigationRouter
    @State private var model: MissedViewModel
    @State private var isFiltering = false
    @Environment(\.dynamicTypeSize) private var typeSize

    init(dependencies: AppDependencies, router: NavigationRouter) {
        self.dependencies = dependencies
        self.router = router
        _model = State(initialValue: MissedViewModel(tasks: dependencies.tasks, clock: dependencies.clock))
    }

    var body: some View {
        NavigationStack {
            TimelineView(.everyMinute) { _ in
                list
            }
            .navigationTitle("Missed")
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

    private var todaySection: some View {
        Section {
            if model.isLoaded, model.todayItems.isEmpty {
                Text("You haven't missed a task today").foregroundStyle(.secondary)
            }
            ForEach(model.todayItems) { item in
                VStack(alignment: .leading, spacing: 8) {
                    MissedRow(item: item, dueText: model.dueText(item))
                    actions(for: item)
                }
                .listRowBackground(model.highlighted.contains(item.id) ? Color.accentColor.opacity(0.15) : nil)
            }
        } header: {
            Text("Today")
        } footer: {
            if !model.todayItems.isEmpty {
                Text("You can still change these")
            }
        }
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
                Button("Log time") { router.logTime = LogTimeRequest(taskID: item.occurrence.task.id) }
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
                Text("Nothing missed before today").foregroundStyle(.secondary)
            } else if model.isLoaded, model.earlierCount == 0 {
                VStack(spacing: 8) {
                    Text("No missed tasks match these filters").foregroundStyle(.secondary)
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
                    Text("\(model.earlierCount) missed").textCase(nil)
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
