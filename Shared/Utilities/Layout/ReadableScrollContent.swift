import SwiftUI

/// Keeps a list's or scroll view's rows within the readable width, centered, while the scroll view and its
/// background still fill the screen, so it scrolls from anywhere (SPEC F-25).
struct ReadableScrollContent: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { proxy in
            content.contentMargins(.horizontal, ReadableWidth.margin(in: proxy.size.width), for: .scrollContent)
        }
    }
}
