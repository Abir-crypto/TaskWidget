import Core
import SwiftUI

/// A clock counting up from the timer's start, frozen while paused. It updates itself.
struct TimerClock: View {
    let timer: ActiveTimer
    /// "Now" from the app's `Clock`, which decides the time counted so far.
    let now: Date

    var body: some View {
        // The elapsed time comes from the app's clock; the self-updating text then counts on in real time
        // from that point.
        let displayNow = Date()
        let start = displayNow.addingTimeInterval(-TimerRules.elapsed(timer.state, now: now))
        Text(
            timerInterval: start...start.addingTimeInterval(60 * 60 * 24 * 7),
            pauseTime: timer.isRunning ? nil : displayNow,
            countsDown: false, showsHours: true
        )
        .monospacedDigit()
    }
}
