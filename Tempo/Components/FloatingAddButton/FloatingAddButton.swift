import SwiftUI

/// The floating + button on Today and Tasks (SPEC F-09, ios.md §12).
struct FloatingAddButton: View {
    /// Space kept free under scrolling content, so the last row is never hidden under the button.
    static let reservedHeight: CGFloat = 88

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .frame(width: 56, height: 56)
                .background(.tint, in: Circle())
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
        .padding(20)
        .accessibilityLabel("Add task")
    }
}

extension View {
    /// Puts the + button in the bottom trailing corner and keeps scrolling content clear of it.
    func floatingAddButton(action: @escaping () -> Void) -> some View {
        overlay(alignment: .bottomTrailing) { FloatingAddButton(action: action) }
            .contentMargins(.bottom, FloatingAddButton.reservedHeight, for: .scrollContent)
    }
}

#Preview {
    List(1...30, id: \.self) { Text(verbatim: "Row \($0)") }
        .floatingAddButton {}
}
