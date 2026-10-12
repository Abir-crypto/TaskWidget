import Core
import Foundation

/// What the Timer widget shows (SPEC F-18). Every timer has Pause or Resume and Done (D-111).
enum TimerWidgetState: Hashable {
    /// No timer: "Timer" and Start.
    case idle
    /// A generic timer: the clock, Pause or Resume, and Done, which opens the task picker.
    case generic(TimerClockValue)
    /// A habit timer: the habit's name, the clock or the time so far with "Paused", Pause or Resume, and Done, which
    /// saves without opening the app.
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
