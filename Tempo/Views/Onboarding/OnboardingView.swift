import SwiftUI

/// The first-launch guide's swipeable pages, or pages 1–5 again from Settings › How to use (SPEC F-23).
struct OnboardingView: View {
    @State private var model: OnboardingViewModel
    /// Page 6's part times, saved on every change as in Settings.
    @State private var parts: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    init(dependencies: AppDependencies, mode: GuideMode) {
        _model = State(
            initialValue: OnboardingViewModel(
                mode: mode, deviceState: dependencies.deviceState, notifications: dependencies.notifications,
                reminders: dependencies.reminders))
        _parts = State(
            initialValue: SettingsViewModel(manager: dependencies.settings, notifications: dependencies.notifications))
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            TabView(selection: $model.page) {
                ForEach(model.pages) { page in
                    pageView(page).tag(page)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            bottomButtons
        }
        .task { await parts.load() }
    }

    /// Skip on pages 1–5 of the first-launch guide; Done in How to use until its last page, which has its own.
    private var topBar: some View {
        HStack {
            Spacer()
            if model.showsSkip {
                Button("Skip") { withAnimation { model.skip() } }
            } else if model.mode == .howToUse && model.nextPage != nil {
                Button("Done") { dismiss() }
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func pageView(_ page: OnboardingPage) -> some View {
        if page == .partsOfTheDay {
            OnboardingPageView(page: page) {
                VStack(spacing: 12) {
                    PartStartPickers(model: parts)
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                .padding(.top, 8)
            }
        } else {
            OnboardingPageView(page: page)
        }
    }

    /// Next on every page but the last; page 7 has Allow and Not now, and How to use ends with Done.
    @ViewBuilder
    private var bottomButtons: some View {
        VStack(spacing: 8) {
            if model.page == .notifications {
                Button {
                    Task {
                        await model.allowNotifications()
                        dismiss()
                    }
                } label: {
                    Text("Allow").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                Button("Not now") {
                    model.finish()
                    dismiss()
                }
                .padding(.vertical, 8)
            } else if model.nextPage != nil {
                Button {
                    withAnimation { model.next() }
                } label: {
                    Text("Next").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    dismiss()
                } label: {
                    Text("Done").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .controlSize(.large)
        .frame(maxWidth: 560)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
}

#Preview("First launch") {
    OnboardingView(dependencies: .preview(), mode: .firstLaunch)
}

#Preview("How to use") {
    OnboardingView(dependencies: .preview(), mode: .howToUse)
}
