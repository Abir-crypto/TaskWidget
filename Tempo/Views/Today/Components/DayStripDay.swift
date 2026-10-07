import Core

/// A day in the day strip, with its dot (SPEC F-10).
struct DayStripDay: Identifiable, Hashable {
    enum Dot: Hashable {
        case none
        /// The day has tasks.
        case tasks
        /// The day has missed tasks.
        case missed
    }

    let day: DayKey
    let dot: Dot
    let isToday: Bool

    var id: Int { day.rawValue }
}
