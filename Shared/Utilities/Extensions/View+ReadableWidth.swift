import SwiftUI

extension View {
    /// Limits fixed content, such as Today's day strip, to the readable width, centered (SPEC F-25).
    func readableWidth() -> some View {
        frame(maxWidth: ReadableWidth.maxWidth).frame(maxWidth: .infinity)
    }

    /// Limits a list's or scroll view's rows to the readable width, centered, while it still fills the screen.
    func readableScrollContent() -> some View {
        modifier(ReadableScrollContent())
    }
}
