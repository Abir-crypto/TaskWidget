import SwiftUI

/// "Added 18 min to Read · 28 of 30 min today", with Undo and Change task (SPEC F-06). Shown in the timer
/// bar's place for about 5 seconds.
struct ConfirmationToast: View {
    let toast: TimerToast
    let onUndo: () -> Void
    let onChangeTask: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(toast.message)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            if toast.entry != nil {
                HStack(spacing: 8) {
                    Button("Undo", action: onUndo)
                    Button("Change task", action: onChangeTask)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
        .accessibilityElement(children: .contain)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    ConfirmationToast(
        toast: TimerToast(message: "Less than a minute, nothing saved.", entry: nil), onUndo: {}, onChangeTask: {})
}
