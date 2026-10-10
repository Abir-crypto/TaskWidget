import Core
import SwiftUI

/// The Tasks tab (SPEC F-11): Habits and One-time, with History behind the clock button.
struct TasksView: View {
    let dependencies: AppDependencies
    @Bindable var router: NavigationRouter
    @State private var model: TasksViewModel
    @AppStorage("tasksSegment") private var segment: TasksSegment = .habits

    init(dependencies: AppDependencies, router: NavigationRouter) {
        self.dependencies = dependencies
        self.router = router
        _model = State(initialValue: TasksViewModel(tasks: dependencies.tasks, clock: dependencies.clock))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("List", selection: $segment) {
                    ForEach(TasksSegment.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .readableWidth()
                switch segment {
                case .habits: habitsList
                case .oneTime: oneTimeList
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        router.isHistoryPresented = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .accessibilityLabel("History")
                }
            }
            .navigationDestination(isPresented: $router.isHistoryPresented) {
                HistoryView(dependencies: dependencies)
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .habit(let id): HabitDetailView(dependencies: dependencies, taskID: id)
                }
            }
            .floatingAddButton { router.openEditor(.new(type: segment == .habits ? .progress : .oneTime)) }
        }
        .safeAreaInset(edge: .bottom) { TimerBar() }
        .task(id: dependencies.refresh.revision) { model.load() }
    }

    @ViewBuilder
    private var habitsList: some View {
        if model.isLoaded, model.habits.isEmpty {
            ContentUnavailableView {
                Label("No habits yet", systemImage: TaskType.progress.systemImage)
            } actions: {
                Button("Add a habit") { router.openEditor(.new(type: .progress)) }
                    .buttonStyle(.borderedProminent)
            }
        } else {
            List(model.habits) { habit in
                NavigationLink(value: Route.habit(habit.task.id)) {
                    HabitRow(habit: habit)
                }
            }
            .readableScrollContent()
        }
    }

    @ViewBuilder
    private var oneTimeList: some View {
        if model.isLoaded, model.oneTimeGroups.isEmpty {
            ContentUnavailableView {
                Label("No upcoming tasks", systemImage: TaskType.oneTime.systemImage)
            } actions: {
                Button("Add a task") { router.openEditor(.new(type: .oneTime)) }
                    .buttonStyle(.borderedProminent)
            }
        } else {
            List {
                ForEach(model.oneTimeGroups) { group in
                    Section(group.title) {
                        ForEach(group.items) { item in
                            Button {
                                router.openEditor(.edit(item.task.id))
                            } label: {
                                OneTimeRow(item: item).contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .readableScrollContent()
        }
    }
}

#Preview("Sample") {
    let dependencies = AppDependencies.preview(hour: 13, sample: true)
    return TasksView(dependencies: dependencies, router: NavigationRouter()).previewEnvironment(dependencies)
}

#Preview("Empty") {
    let dependencies = AppDependencies.preview()
    return TasksView(dependencies: dependencies, router: NavigationRouter()).previewEnvironment(dependencies)
}
