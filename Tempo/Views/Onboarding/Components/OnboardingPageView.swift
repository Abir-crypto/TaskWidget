import SwiftUI

/// One page of the guide: its icon, title and text, with room for page 6's pickers (SPEC F-23).
struct OnboardingPageView<Content: View>: View {
    let page: OnboardingPage
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: page.systemImage)
                    .font(.system(size: 64))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                    .padding(.top, 40)
                Text(page.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(page.message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                content
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }
}

extension OnboardingPageView where Content == EmptyView {
    init(page: OnboardingPage) {
        self.init(page: page) { EmptyView() }
    }
}

#Preview {
    OnboardingPageView(page: .welcome)
}
