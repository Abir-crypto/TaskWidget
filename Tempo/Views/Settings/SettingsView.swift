import Core
import SwiftUI
import UIKit

/// Settings, opened from the gear on Today (SPEC F-16).
struct SettingsView: View {
    let dependencies: AppDependencies
    @State private var model: SettingsViewModel
    @Environment(\.openURL) private var openURL
    @Environment(NavigationRouter.self) private var router

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _model = State(
            initialValue: SettingsViewModel(
                manager: dependencies.settings, notifications: dependencies.notifications, missed: dependencies.missed))
    }

    var body: some View {
        Form {
            partsSection
            missedStyleSection
            remindersSection
            notificationsSection
            themeSection
            privacySection
            helpSection
            aboutSection
        }
        .readableScrollContent()
        .navigationTitle("Settings")
        .task(id: dependencies.refresh.revision) { await model.load() }
    }

    // MARK: Parts of the day

    private var partsSection: some View {
        Section {
            PartStartPickers(model: model)
        } header: {
            Text("Parts of the day")
        } footer: {
            Text(
                "Each part ends when the next one starts, and Night ends at midnight. Every part lasts at least 30 minutes."
            )
        }
    }

    // MARK: Missed tasks

    /// Gentle or Strict (SPEC F-16, F-30).
    private var missedStyleSection: some View {
        Section {
            MenuValuePicker(
                title: "Missed tasks", selection: binding(\.missedStyle), options: MissedStyle.allCases
            ) { Text($0.title) }
        } footer: {
            Text(
                "Gentle shows tasks you didn't get to as Not done, without a badge or a popup. Strict marks them Missed in red."
            )
        }
    }

    // MARK: Reminders

    private var remindersSection: some View {
        Section {
            // A summary when each part starts, with a switch per part; only Morning's is on by default (D-109).
            ForEach(DayPart.allCases, id: \.self) { part in
                Toggle(String(localized: "\(part.title) starts"), isOn: partStartBinding(part))
            }

            Toggle("Ending soon", isOn: binding(\.notifyEndingSoon))
            if model.settings.notifyEndingSoon {
                MenuValuePicker(
                    title: "Before the part ends", selection: binding(\.endingSoonLead),
                    options: SettingsValue.endingSoonLeadChoices
                ) { Text("\($0) min") }
            }

            Toggle("Fixed-time tasks", isOn: binding(\.notifyFixed))
            if model.settings.notifyFixed {
                MenuValuePicker(
                    title: "Before the task", selection: binding(\.fixedLead), options: SettingsValue.fixedLeadChoices
                ) { Text("\($0) min") }
            }

            Toggle("End-of-day recap", isOn: binding(\.notifyRecap))
            if model.settings.notifyRecap, let first = model.settings.recapChoices.first {
                LabeledContent("Recap time") {
                    MinuteIntervalPicker(
                        minute: binding(\.recapMinute),
                        interval: SettingsValue.recapStep,
                        range: first...SettingsValue.latestRecapMinute,
                        accessibilityLabel: String(localized: "Recap time"))
                }
            }

            Toggle("Running timer alert", isOn: binding(\.notifyTimer))
            if model.settings.notifyTimer {
                MenuValuePicker(
                    title: "Alert after", selection: binding(\.timerAlertMinutes),
                    options: SettingsValue.timerAlertChoices
                ) { Text("^[\($0 / 60) hour](inflect: true)") }
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text(
                "A summary when each part starts, a reminder before a part ends, a reminder before fixed-time tasks, a recap of the day, and an alert when a timer has been running a long time."
            )
        }
    }

    // MARK: Notifications

    @ViewBuilder
    private var notificationsSection: some View {
        Section {
            switch model.permission {
            case .allowed:
                LabeledContent("Notifications", value: String(localized: "On"))
            case .denied:
                LabeledContent("Notifications", value: String(localized: "Off"))
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                }
            case .notDetermined:
                LabeledContent("Notifications", value: String(localized: "Not allowed yet"))
                Button("Allow notifications") {
                    Task { await model.requestPermission() }
                }
            case nil:
                LabeledContent("Notifications") { ProgressView() }
            }
        } footer: {
            if model.permission == .denied {
                Text("Notifications are off for Tempo, so no reminders are sent. Turn them on in the Settings app.")
            }
        }
    }

    // MARK: Theme

    /// The app's appearance and color (SPEC F-28, F-27). Both apply at once, through the root view (ios.md §12).
    private var themeSection: some View {
        Section {
            Picker("Appearance", selection: binding(\.appearance)) {
                ForEach(Appearance.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            ThemePicker(selection: model.settings.tintColor) { color in
                model.update { $0.tintColor = color }
            }
        } header: {
            Text("Theme")
        } footer: {
            Text(
                "System follows your device's light or dark mode, as the widgets always do. The color is used for buttons, checkboxes and highlights in the app and its widgets."
            )
        }
    }

    // MARK: Privacy, Help and About

    private var privacySection: some View {
        Section {
            Toggle("Hide task names on the Lock Screen", isOn: binding(\.hideLockScreenTitles))
        } header: {
            Text("Privacy")
        } footer: {
            Text("Task names stay hidden on the Lock Screen widgets until your iPhone or iPad is unlocked.")
        }
    }

    /// How to use reopens pages 1–5 of the guide (SPEC F-16, F-23).
    private var helpSection: some View {
        Section("Help") {
            Button("How to use") { router.guide = .howToUse }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: model.appVersion)
        }
    }

    /// A binding to one setting that saves on every change.
    private func partStartBinding(_ part: DayPart) -> Binding<Bool> {
        Binding(
            get: { model.settings.partStartSummaries.contains(part) },
            set: { on in
                model.update { settings in
                    if on {
                        settings.partStartSummaries.insert(part)
                    } else {
                        settings.partStartSummaries.remove(part)
                    }
                }
            })
    }

    private func binding<Value: Equatable>(_ keyPath: WritableKeyPath<SettingsValue, Value>) -> Binding<Value> {
        Binding(
            get: { model.settings[keyPath: keyPath] },
            set: { newValue in model.update { $0[keyPath: keyPath] = newValue } })
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    return NavigationStack { SettingsView(dependencies: dependencies) }.previewEnvironment(dependencies)
}
