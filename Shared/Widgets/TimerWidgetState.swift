import Core
import Foundation

/// What the Timer widget shows (SPEC F-18). Only generic timers get controls here; a habit timer is display only.
enum TimerWidgetState: Hashable {
    /// No timer: "Timer" and Start.
    case idle
    /// A generic timer: the clock, Pause or Resume, and Done.
    case generic(TimerClockValue)
    /// A habit timer started elsewhere: the habit's name and the clock or "Paused"; tapping opens the app.
    case habit(title: String, clock: TimerClockValue)

    init(timer: TimerState?, habitTitle: String?) {
        guard let timer else {
            self = .idle
            return
        }
        let clock = TimerClockValue(state: timer)
        switch timer.kind {
        case .generic: self = .generic(clock)
        case .habit: self = .habit(title: habitTitle ?? String(localized: "Timer"), clock: clock)
        }
    }

    /// Where tapping outside the buttons leads: the timer screen while a timer exists, otherwise Today.
    var url: URL {
        self == .idle ? DeepLink.today().url : DeepLink.timer.url
    }
}
