import Foundation

/// Formats minutes as a short duration: "45m", "1h 20m", "2h" (SPEC F-10 "ends in 1h 20m").
enum DurationFormatter {
    static func short(minutes: Int) -> String {
        let style = Duration.UnitsFormatStyle(allowedUnits: [.hours, .minutes], width: .narrow)
        return Duration.seconds(max(minutes, 0) * 60).formatted(style)
    }

    /// "10 of 30 min".
    static func progress(minutes: Int, target: Int) -> String {
        String(localized: "\(minutes) of \(target) min")
    }
}
