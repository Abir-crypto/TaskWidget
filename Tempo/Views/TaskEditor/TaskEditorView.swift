import Core
import SwiftUI

/// The task editor, presented as a sheet (SPEC F-15).
struct TaskEditorView: View {
    let dependencies: AppDependencies
    @State private var model: TaskEditorViewModel
    @State private var confirming: TaskEditorViewModel.DestructiveAction?
    @Environment(\.dismiss) private var dismiss

    init(dependencies: AppDependencies, request: EditorRequest) {
        self.dependencies = dependencies
        _model = State(
            initialValue: TaskEditorViewModel(tasks: dependencies.tasks, clock: dependencies.clock, request: request))
    }

    var body: some View {
        NavigationStack {
            Form {
                typeSection
                titleSection
                timingSection
                if model.type == .oneTime {
                    dateSection
                } else {
                    habitSection
                }
                if model.type == .duration {
                    targetSection
                }
                if model.isEditing, !model.isReadOnly {
                    destructiveSection
                }
            }
            .disabled(model.isReadOnly)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(model.isReadOnly ? "Close" : "Cancel") { dismiss() }
                }
                if !model.isReadOnly {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if model.save() { dismiss() }
                        }
                        .disabled(!model.canSave)
                    }
                }
            }
            .task { model.load() }
            .alert(
                "Couldn't save",
                isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } }),
                presenting: model.errorMessage
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
            .confirmationDialog(
                confirmationTitle,
                isPresented: Binding(get: { confirming != nil }, set: { if !$0 { confirming = nil } }),
                titleVisibility: .visible,
                presenting: confirming
            ) { action in
                confirmationButtons(for: action)
            } message: { action in
                Text(confirmationMessage(for: action))
            }
        }
    }

    private var navigationTitle: LocalizedStringKey {
        if model.isReadOnly { return "Task" }
        return model.isEditing ? "Edit task" : "New task"
    }

    // MARK: Type and title

    private var typeSection: some View {
        Section {
            if model.isEditing {
                LabeledContent("Type", value: model.type.title)
            } else {
                Picker("Type", selection: $model.type) {
                    ForEach(TaskType.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }
        } footer: {
            if model.isEditing {
                Text("The type can't be changed after a task is created.")
            } else {
                Text(model.type.explanation)
            }
        }
    }

    private var titleSection: some View {
        Section {
            TextField("Title", text: $model.title, axis: .vertical)
                .accessibilityLabel("Title")
        } footer: {
            if let message = model.titleMessage {
                Text(message).foregroundStyle(.red)
            }
        }
    }

    // MARK: When

    private var timingSection: some View {
        Section {
            Picker("When", selection: $model.timingKind) {
                Text("Fixed time").tag(TimingKind.fixed)
                Text("Part of the day").tag(TimingKind.part)
                Text("Anytime").tag(TimingKind.anytime)
            }
            .pickerStyle(.segmented)
            .disabled(!model.canEditSchedule)

            switch model.timingKind {
            case .fixed:
                LabeledContent("Time") {
                    MinuteIntervalPicker(
                        minute: $model.fixedMinute, interval: Timing.fixedStep, range: model.fixedMinuteRange,
                        accessibilityLabel: String(localized: "Time"))
                }
                .disabled(!model.canEditSchedule)
            case .part:
                ForEach(DayPart.allCases, id: \.self) { part in
                    partRow(part)
                }
            case .anytime:
                EmptyView()
            }
        } header: {
            Text("When")
        } footer: {
            if model.validationError == .partAlreadyOver {
                Text("That part of the day is already over. Pick a later time.").foregroundStyle(.red)
            } else if model.timingKind == .anytime {
                Text("Anytime tasks belong to no part of the day and stay open until midnight.")
            }
        }
    }

    private func partRow(_ part: DayPart) -> some View {
        let isOver = model.isOver(part)
        let isSelected = model.part == part
        return Button {
            model.part = part
        } label: {
            HStack {
                Text(part.title)
                    .foregroundStyle(isOver ? .secondary : .primary)
                Spacer()
                if isOver {
                    Text("Already over").font(.footnote).foregroundStyle(.secondary)
                }
                if isSelected {
                    Image(systemName: "checkmark").foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled((isOver && !isSelected) || !model.canEditSchedule)
        .accessibilityLabel(part.title)
        .accessibilityValue(isOver ? String(localized: "Already over") : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: Date and habit fields

    private var dateSection: some View {
        Section {
            DatePicker(
                "Date",
                selection: dayBinding($model.date),
                in: model.today.startDate(in: model.calendar)...,
                displayedComponents: .date)
        }
    }

    private var habitSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Repeat on")
                WeekdayPicker(selection: $model.weekdays, calendar: model.calendar)
                    .disabled(!model.canEditSchedule)
                if let message = model.weekdaysMessage {
                    Text(message).font(.footnote).foregroundStyle(.red)
                }
            }
            DatePicker(
                "Starts",
                selection: dayBinding($model.startDay),
                in: model.today.startDate(in: model.calendar)...,
                displayedComponents: .date
            )
            .disabled(!model.canEditStartDay)
            Toggle("Set length", isOn: $model.hasLength)
                .disabled(!model.canEditSchedule)
            if model.hasLength {
                Stepper(value: $model.lengthDays, in: TaskRules.lengthRange) {
                    Text("^[\(model.lengthDays) day](inflect: true)")
                }
                .disabled(!model.canEditSchedule)
            }
        } header: {
            Text("Schedule")
        } footer: {
            if model.showsScheduleNote {
                Text("Changes apply from today. Earlier days keep their old schedule.")
            } else if !model.hasLength {
                Text("Ongoing until you end it.")
            }
        }
    }

    private var targetSection: some View {
        Section {
            Stepper(value: $model.targetMinutes, in: TaskRules.targetRange, step: TaskRules.targetStep) {
                LabeledContent("Daily target", value: String(localized: "\(model.targetMinutes) min"))
            }
            .disabled(!model.canEditSchedule)
        }
    }

    // MARK: Delete and end

    @ViewBuilder
    private var destructiveSection: some View {
        Section {
            if model.type == .oneTime {
                Button("Delete task", role: .destructive) { confirming = .deleteOneTime }
            } else {
                if model.canEditSchedule {
                    Button("End habit") { confirming = .endHabit }
                }
                Button("Delete with history", role: .destructive) { confirming = .deleteWithHistory }
            }
        }
    }

    private var confirmationTitle: LocalizedStringKey {
        switch confirming {
        case .deleteOneTime: "Delete this task?"
        case .endHabit: "End this habit?"
        case .deleteWithHistory: "Delete this habit and its history?"
        case nil: ""
        }
    }

    private func confirmationMessage(for action: TaskEditorViewModel.DestructiveAction) -> LocalizedStringKey {
        switch action {
        case .deleteOneTime: "This can't be undone."
        case .endHabit: "It moves to History with its stats, and you can start it again later."
        case .deleteWithHistory:
            "All of its history and stats will be deleted. This can't be undone. End the habit instead to keep them."
        }
    }

    @ViewBuilder
    private func confirmationButtons(for action: TaskEditorViewModel.DestructiveAction) -> some View {
        switch action {
        case .deleteOneTime:
            Button("Delete task", role: .destructive) { finish(.deleteOneTime) }
        case .endHabit:
            Button("End habit") { finish(.endHabit) }
        case .deleteWithHistory:
            Button("Delete with history", role: .destructive) { finish(.deleteWithHistory) }
            if model.canEditSchedule {
                Button("End habit") { finish(.endHabit) }
            }
        }
        Button("Cancel", role: .cancel) {}
    }

    private func finish(_ action: TaskEditorViewModel.DestructiveAction) {
        if model.perform(action) { dismiss() }
    }

    /// A date binding over a day key, in the clock's calendar.
    private func dayBinding(_ day: Binding<DayKey>) -> Binding<Date> {
        Binding(
            get: { day.wrappedValue.startDate(in: model.calendar) },
            set: { day.wrappedValue = DayKey($0, calendar: model.calendar) })
    }
}

#Preview("New") {
    TaskEditorView(dependencies: .preview(), request: .new())
}

#Preview("New duration habit") {
    TaskEditorView(dependencies: .preview(hour: 18), request: .new(type: .duration))
}
