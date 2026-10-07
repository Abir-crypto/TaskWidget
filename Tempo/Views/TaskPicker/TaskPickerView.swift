import Core
import SwiftUI

/// The task picker for a finished generic timer, or for moving a saved entry with "Change task" (SPEC F-06).
struct TaskPickerView: View {
    let dependencies: AppDependencies
    @State private var model: TaskPickerViewModel
    @Environment(TimerController.self) private var controller
    @Environment(NavigationRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    init(dependencies: AppDependencies, request: TaskPickerRequest) {
        self.dependencies = dependencies
        _model = State(initialValue: TaskPickerViewModel(tasks: dependencies.tasks, request: request))
    }

    var body: some View {
        NavigationStack {
            Group {
                if model.isLoaded, model.habits.isEmpty {
                    ContentUnavailableView {
                        Label("No duration tasks yet", systemImage: TaskType.duration.systemImage)
                    } actions: {
                        Button("Add a duration task") {
                            // The time is kept: the picker comes back when the editor closes (D-084).
                            router.resumePickerAfterEditor = model.request
                            router.taskPicker = nil
                            router.openEditor(.new(type: .duration))
                        }
                        .buttonStyle(.borderedProminent)
                        if !model.isMoving {
                            Button("Discard", role: .destructive) { dismiss() }
                        }
                    }
                } else {
                    List {
                        Section {
                            ForEach(model.habits) { habit in
                                Button {
                                    controller.choose(habit.task.id, for: model.request)
                                } label: {
                                    LabeledContent(habit.task.title, value: habit.progress)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            Text(model.isMoving ? "Move \(model.timeText) to" : "Add \(model.timeText) to")
                        }
                    }
                }
            }
            .navigationTitle("Choose a task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if model.isMoving {
                        Button("Cancel") { dismiss() }
                    } else {
                        Button("Discard", role: .destructive) { dismiss() }
                    }
                }
            }
            .task { model.load() }
        }
        // A finished timer's time is only kept by choosing a task or tapping Discard.
        .interactiveDismissDisabled(!model.isMoving)
    }
}

#Preview {
    let dependencies = AppDependencies.preview(hour: 13, sample: true)
    let router = NavigationRouter()
    return TaskPickerView(
        dependencies: dependencies,
        request: TaskPickerRequest(
            timer: FinishedTimer(habitID: nil, day: DayKey(year: 2026, month: 10, day: 6), seconds: 1_080))
    )
    .environment(TimerController(dependencies: dependencies, router: router))
    .environment(router)
}
