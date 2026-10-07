/// The user's start times for the four parts of the day, in minutes after midnight (SPEC F-02, §5.2).
public struct PartSettings: Hashable, Codable, Sendable {
    public var morningStart: Int
    public var noonStart: Int
    public var eveningStart: Int
    public var nightStart: Int

    public init(morningStart: Int, noonStart: Int, eveningStart: Int, nightStart: Int) {
        self.morningStart = morningStart
        self.noonStart = noonStart
        self.eveningStart = eveningStart
        self.nightStart = nightStart
    }

    /// Morning 06:00, Noon 12:00, Evening 17:00, Night 21:00 (SPEC §4.5).
    public static let defaults = PartSettings(morningStart: 360, noonStart: 720, eveningStart: 1020, nightStart: 1260)

    /// Part start times use 15-minute steps (SPEC F-02).
    public static let step = 15

    /// Each part lasts at least 30 minutes (SPEC F-02).
    public static let minimumLength = 30

    public func start(of part: DayPart) -> Int {
        switch part {
        case .morning: morningStart
        case .noon: noonStart
        case .evening: eveningStart
        case .night: nightStart
        }
    }

    /// Where the part ends: the next part's start, or midnight (1440) for Night.
    public func end(of part: DayPart) -> Int {
        guard let next = part.next else { return DayKey.minutesPerDay }
        return start(of: next)
    }

    /// The part's window, `[start, end)`.
    public func window(of part: DayPart) -> Range<Int> {
        start(of: part)..<end(of: part)
    }

    /// The part that contains a minute of the day. Minutes before Morning's start belong to Morning (SPEC §5.2).
    public func part(containing minute: Int) -> DayPart {
        if minute < noonStart { return .morning }
        if minute < eveningStart { return .noon }
        if minute < nightStart { return .evening }
        return .night
    }

    /// Returns a copy with one part's start changed.
    public func setting(_ part: DayPart, to minute: Int) -> PartSettings {
        var copy = self
        switch part {
        case .morning: copy.morningStart = minute
        case .noon: copy.noonStart = minute
        case .evening: copy.eveningStart = minute
        case .night: copy.nightStart = minute
        }
        return copy
    }

    /// The first rule the start times break, or `nil` when they're valid.
    public var validationError: PartSettingsError? {
        for part in DayPart.allCases {
            let start = start(of: part)
            if start < 0 || start >= DayKey.minutesPerDay { return .outOfRange(part) }
            if start % PartSettings.step != 0 { return .notOnStep(part) }
        }
        for part in DayPart.allCases {
            guard let next = part.next else { continue }
            if start(of: next) <= start(of: part) { return .outOfOrder(next) }
        }
        for part in DayPart.allCases where end(of: part) - start(of: part) < PartSettings.minimumLength {
            return .tooShort(part)
        }
        return nil
    }

    public var isValid: Bool { validationError == nil }

    /// The start times a part can take while the other three stay put, in 15-minute steps.
    /// Every value keeps all four parts at least 30 minutes long.
    public func allowedStarts(for part: DayPart) -> [Int] {
        let lowest: Int
        switch part {
        case .morning: lowest = 0
        case .noon: lowest = morningStart + PartSettings.minimumLength
        case .evening: lowest = noonStart + PartSettings.minimumLength
        case .night: lowest = eveningStart + PartSettings.minimumLength
        }
        let highest = end(of: part) - PartSettings.minimumLength
        let first = (lowest + PartSettings.step - 1) / PartSettings.step * PartSettings.step
        guard first <= highest else { return [] }
        return Array(stride(from: first, through: highest, by: PartSettings.step))
    }
}

/// Why a set of part start times was rejected (SPEC F-02).
public enum PartSettingsError: Error, Hashable, Sendable {
    /// The start is before midnight or past the end of the day.
    case outOfRange(DayPart)
    /// The start isn't on a 15-minute step.
    case notOnStep(DayPart)
    /// The part starts at or before the previous part's start.
    case outOfOrder(DayPart)
    /// The part would last less than 30 minutes.
    case tooShort(DayPart)
}
