import Core
import SwiftUI

/// A start-time picker for each part of the day, in 15-minute steps and limited to times that keep the F-02
/// rules. Used by Settings and the guide's page 6 (SPEC F-16, F-23).
struct PartStartPickers: View {
    let model: SettingsViewModel

    var body: some View {
        ForEach(DayPart.allCases, id: \.self) { part in
            LabeledContent(part.title) {
                MinuteIntervalPicker(
                    minute: Binding(
                        get: { model.settings.parts.start(of: part) },
                        set: { model.setStart(of: part, to: $0) }),
                    interval: PartSettings.step,
                    range: model.allowedStarts(for: part),
                    accessibilityLabel: String(localized: "\(part.title) starts at"))
            }
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    let model = SettingsViewModel(manager: dependencies.settings, notifications: dependencies.notifications)
    return Form { PartStartPickers(model: model) }
        .task { await model.load() }
}
