import Core
import SwiftUI

/// "You missed 2 tasks today", with the tasks, Review missed tasks and Not now (SPEC F-08, ios.md §12).
struct MissedPopupView: View {
    let content: MissedPopupContent
    let onReview: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.red)
                .accessibilityHidden(true)
            Text("You missed ^[\(content.items.count) task](inflect: true) today")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
            List(content.items) { item in
                HStack {
                    Image(systemName: item.occurrence.type.systemImage)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(item.occurrence.task.title)
                    Spacer()
                    Text(ScheduleFormatter.timing(item.occurrence.timing))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.plain)
            .frame(maxHeight: 220)
            VStack(spacing: 8) {
                Button(action: onReview) {
                    Text("Review missed tasks").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                Button("Not now", action: onNotNow)
                    .controlSize(.large)
            }
        }
        .padding()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        MissedPopupView(content: MissedPopupContent(items: []), onReview: {}, onNotNow: {})
    }
}
