import Foundation

/// The single `settings` row (SPEC §4.5).
public struct SettingsValue: Hashable, Codable, Sendable {
    public var parts: PartSettings
    public var notifyPartStart: Bool
    public var notifyEndingSoon: Bool
    /// Minutes before a part ends: 15, 30, 45 or 60.
    public var endingSoonLead: Int
    public var notifyFixed: Bool
    /// Minutes before a fixed-time task: 5, 10, 15 or 30.
    public var fixedLead: Int
    public var notifyRecap: Bool
    /// Minute of day of the end-of-day recap, in 15-minute steps from Night's start to 23:45.
    public var recapMinute: Int
    public var notifyTimer: Bool
    /// The running-timer alert period in minutes: 60, 120 or 180.
    public var timerAlertMinutes: Int
    public var hideLockScreenTitles: Bool
    /// `nil` until the row is first saved.
    public var updatedAt: Date?

    public init(
        parts: PartSettings = .defaults,
        notifyPartStart: Bool = true,
        notifyEndingSoon: Bool = true,
        endingSoonLead: Int = 30,
        notifyFixed: Bool = true,
        fixedLead: Int = 10,
        notifyRecap: Bool = true,
        recapMinute: Int = 1410,
        notifyTimer: Bool = true,
        timerAlertMinutes: Int = 120,
        hideLockScreenTitles: Bool = false,
        updatedAt: Date? = nil
    ) {
        self.parts = parts
        self.notifyPartStart = notifyPartStart
        self.notifyEndingSoon = notifyEndingSoon
        self.endingSoonLead = endingSoonLead
        self.notifyFixed = notifyFixed
        self.fixedLead = fixedLead
        self.notifyRecap = notifyRecap
        self.recapMinute = recapMinute
        self.notifyTimer = notifyTimer
        self.timerAlertMinutes = timerAlertMinutes
        self.hideLockScreenTitles = hideLockScreenTitles
        self.updatedAt = updatedAt
    }

    /// Every default from SPEC §4.5: the default part times, every reminder on, names shown on the Lock Screen.
    public static let defaults = SettingsValue()

    public static let endingSoonLeadChoices = [15, 30, 45, 60]
    public static let fixedLeadChoices = [5, 10, 15, 30]
    public static let timerAlertChoices = [60, 120, 180]
    /// The latest recap time, 23:45.
    public static let latestRecapMinute = 1425
    /// Recap times use 15-minute steps.
    public static let recapStep = 15

    /// The recap times that can be chosen: 15-minute steps from Night's start to 23:45 (SPEC F-16).
    public var recapChoices: [Int] {
        let first = (parts.nightStart + Self.recapStep - 1) / Self.recapStep * Self.recapStep
        guard first <= Self.latestRecapMinute else { return [] }
        return Array(stride(from: first, through: Self.latestRecapMinute, by: Self.recapStep))
    }

    /// The first rule the settings break, or `nil` when they're valid (SPEC F-02, F-16).
    public var validationError: SettingsValidationError? {
        if let error = parts.validationError { return .parts(error) }
        if !Self.endingSoonLeadChoices.contains(endingSoonLead) { return .endingSoonLead }
        if !Self.fixedLeadChoices.contains(fixedLead) { return .fixedLead }
        if !Self.timerAlertChoices.contains(timerAlertMinutes) { return .timerAlert }
        if !recapChoices.contains(recapMinute) { return .recapMinute }
        return nil
    }

    /// The same settings with the recap moved into its allowed range, for when Night's start moves past it:
    /// the recap becomes the first allowed time at or after it, or the last allowed time (D-066).
    public func keepingRecapInRange() -> SettingsValue {
        let choices = recapChoices
        guard !choices.isEmpty, !choices.contains(recapMinute) else { return self }
        var copy = self
        copy.recapMinute = choices.first { $0 >= recapMinute } ?? choices[choices.count - 1]
        return copy
    }
}

/// Why settings were rejected.
public enum SettingsValidationError: Error, Hashable, Sendable {
    case parts(PartSettingsError)
    /// Not 15, 30, 45 or 60 minutes.
    case endingSoonLead
    /// Not 5, 10, 15 or 30 minutes.
    case fixedLead
    /// Not 1, 2 or 3 hours.
    case timerAlert
    /// Not a 15-minute step from Night's start to 23:45.
    case recapMinute
}
