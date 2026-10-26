import ActivityKit
import Core
import SwiftUI
import WidgetKit

/// Sample timers for the Live Activity's previews.
extension TimerActivityAttributes {
    static let previewHabit = TimerActivityAttributes(
        kind: .habit, habitID: UUID(), startDay: DayKey(year: 2026, month: 10, day: 6))
}

extension TimerActivityAttributes.ContentState {
    static let running = TimerActivityAttributes.ContentState(
        runningSince: .now.addingTimeInterval(-312), pausedSeconds: 0, habitTitle: "Read", earlierSeconds: 600,
        targetMinutes: 30, hidesName: false, tint: "blue")
    static let paused = TimerActivityAttributes.ContentState(
        runningSince: nil, pausedSeconds: 312, habitTitle: "Read", earlierSeconds: 600, targetMinutes: 30,
        hidesName: false, tint: "pink")
    static let generic = TimerActivityAttributes.ContentState(
        runningSince: .now.addingTimeInterval(-75), pausedSeconds: 0, habitTitle: nil, earlierSeconds: 0,
        targetMinutes: nil, hidesName: false, tint: "blue")
}
