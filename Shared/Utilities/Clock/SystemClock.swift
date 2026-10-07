import Foundation

/// The real clock and the user's current calendar, which follows time zone and region changes.
struct SystemClock: Clock {
    var now: Date { Date() }
    var calendar: Calendar { Calendar.autoupdatingCurrent }
}
