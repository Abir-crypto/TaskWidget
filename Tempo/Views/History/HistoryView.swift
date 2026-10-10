import Core
import SwiftUI

/// History, opened from the clock on Tasks (SPEC F-12): completed one-time tasks and ended habits.
struct HistoryView: View {
    let dependencies: AppDependencies
    @State private var model: HistoryViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _model = State(initialValue: HistoryViewModel(tasks: dependencies.tasks, clock: dependencies.clock))
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("List", selection: $model.segment) {
                ForEach(HistorySegment.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)
            .readableWidth()
            switch model.segment {
            case .oneTime: oneTimeList
            case .habits: habitsList
            }
        }
        .navigationTitle("History")
        .searchable(text: $model.searchText, prompt: Text("Search"))
        .task(id: dependencies.refresh.revision) { model.load() }
        .alert(
            "Couldn't change the task",
            isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } }),
            presenting: model.errorMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .alert(
            "Started again",
            isPresented: Binding(get: { model.restartedTitle != nil }, set: { if !$0 { model.restartedTitle = nil } }),
            presenting: model.restartedTitle
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { title in
            Text("“\(title)” starts again today. You'll find it in Tasks.")
        }
    }

    @ViewBuilder
    private var oneTimeList: some View {
        let groups = model.completedGroups
        if model.isLoaded, model.segmentIsEmpty {
            ContentUnavailableView("Nothing completed yet", systemImage: "checkmark.circle")
        } else if model.isLoaded, groups.isEmpty {
            ContentUnavailableView("No matches", systemImage: "magnifyingglass")
        } else {
            List {
                ForEach(groups) { group in
                    Section(group.title) {
                        ForEach(group.tasks) { item in
                            CompletedTaskRow(item: item) { model.markNotDone(item) }
                        }
                    }
                }
            }
            .readableScrollContent()
        }
    }

    @ViewBuilder
    private var habitsList: some View {
        let habits = model.endedHabits
        if model.isLoaded, model.segmentIsEmpty {
            ContentUnavailableView("Finished habits will appear here", systemImage: "flag.checkered")
        } else if model.isLoaded, habits.isEmpty {
            ContentUnavailableView("No matches", systemImage: "magnifyingglass")
        } else {
            List(habits) { habit in
                NavigationLink(value: Route.habit(habit.task.id)) {
                    EndedHabitRow(habit: habit) { model.startAgain(habit) }
                }
            }
            .readableScrollContent()
        }
    }
}

#Preview {
    NavigationStack { HistoryView(dependencies: .preview(hour: 13, sample: true)) }
}
