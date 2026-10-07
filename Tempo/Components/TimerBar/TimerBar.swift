import SwiftUI

/// The slot above the tab bar where the timer bar appears while a timer exists (SPEC F-06, F-09).
/// Placed with `.safeAreaInset(edge: .bottom)` on every tab's root, so content scrolls clear of it.
/// It takes no space until the timer arrives in T-20.
struct TimerBar: View {
    var body: some View {
        EmptyView()
    }
}

#Preview {
    List(1...5, id: \.self) { Text(verbatim: "Row \($0)") }
        .safeAreaInset(edge: .bottom) { TimerBar() }
}
