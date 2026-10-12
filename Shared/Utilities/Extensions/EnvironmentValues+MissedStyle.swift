import Core
import SwiftUI

extension EnvironmentValues {
    /// How missed tasks are shown (SPEC F-30). `RootView` sets it from the settings row.
    @Entry var missedStyle: MissedStyle = .default
}
