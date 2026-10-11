import SwiftUI

extension View {
    /// Tints a Home Screen widget with the theme color from its entry's settings, or Blue when the data couldn't be
    /// read (SPEC F-27, ios.md §9).
    func widgetTheme(_ entry: TodayEntry) -> some View {
        tint((entry.snapshot?.core.settings.tintColor ?? .default).color)
    }
}
