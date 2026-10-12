import Core
import SwiftUI

/// The Log time sheet: pick 5–480 minutes and add them to today (SPEC F-05, F-10).
struct LogTimeView: View {
    let dependencies: AppDependencies
    @State private var model: LogTimeViewModel
    @Environment(\.dismiss) private var dismiss

    init(dependencies: AppDependencies, taskID: UUID, day: DayKey? = nil) {
        self.dependencies = dependencies
        _model = State(initialValue: LogTimeViewModel(tasks: dependencies.tasks, taskID: taskID, day: day))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let target = model.targetMinutes {
                        LabeledContent(
                            model.isForYesterday ? "Yesterday" : "Today",
                            value: DurationFormatter.progress(minutes: model.minutesToday, target: target))
                    } else {
                        LabeledContent(
                            model.isForYesterday ? "Yesterday" : "Today",
                            value: String(localized: "\(model.minutesToday) min"))
                    }
                } header: {
                    Text(model.title)
                }
                Section {
                    Picker("Minutes", selection: $model.minutes) {
                        ForEach(model.choices, id: \.self) { Text("\($0) min").tag($0) }
                    }
                    .pickerStyle(.wheel)
                } footer: {
                    if !model.canLog {
                        Text(
                            "Time can be logged today, and yesterday until the afternoon starts, between the habit's start and last day."
                        )
                    }
                }
            }
            .navigationTitle(model.isForYesterday ? "Log time for yesterday" : "Log time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if model.save() { dismiss() }
                    }
                    .disabled(!model.canLog)
                }
            }
            .task { model.load() }
            .alert(
                "Couldn't log time",
                isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } }),
                presenting: model.errorMessage
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    LogTimeView(dependencies: .preview(), taskID: UUID())
}
