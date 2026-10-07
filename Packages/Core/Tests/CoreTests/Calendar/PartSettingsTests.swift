import Testing

@testable import Core

struct PartSettingsTests {
    private let defaults = PartSettings.defaults

    @Test func defaultsMatchTheSpec() {
        #expect(defaults.morningStart == 6 * 60)
        #expect(defaults.noonStart == 12 * 60)
        #expect(defaults.eveningStart == 17 * 60)
        #expect(defaults.nightStart == 21 * 60)
        #expect(defaults.isValid)
    }

    private static let partOfCases: [(minute: Int, part: DayPart)] = [
        (300, .morning),  // 05:00
        (719, .morning),  // 11:59
        (720, .noon),  // 12:00
        (1259, .evening),  // 20:59
        (1260, .night),  // 21:00
        (1439, .night),  // 23:59
        (0, .morning),
        (1019, .noon),  // 16:59
        (1020, .evening),  // 17:00
    ]

    @Test(arguments: partOfCases)
    func partOfWithDefaults(minute: Int, part: DayPart) {
        #expect(defaults.part(containing: minute) == part)
    }

    @Test func windowsWithDefaults() {
        #expect(defaults.window(of: .morning) == 360..<720)
        #expect(defaults.window(of: .noon) == 720..<1020)
        #expect(defaults.window(of: .evening) == 1020..<1260)
        #expect(defaults.window(of: .night) == 1260..<1440)
        #expect(defaults.end(of: .night) == 1440)
    }

    @Test func customTimesMoveTheWindows() {
        let custom = PartSettings(morningStart: 420, noonStart: 690, eveningStart: 1080, nightStart: 1320)
        #expect(custom.isValid)
        #expect(custom.window(of: .morning) == 420..<690)
        #expect(custom.window(of: .noon) == 690..<1080)
        #expect(custom.window(of: .evening) == 1080..<1320)
        #expect(custom.window(of: .night) == 1320..<1440)
        #expect(custom.part(containing: 700) == .noon)
        #expect(custom.part(containing: 1300) == .evening)
        #expect(custom.part(containing: 400) == .morning)
    }

    @Test func rejectsOutOfOrderTimes() {
        let swapped = PartSettings(morningStart: 360, noonStart: 1020, eveningStart: 720, nightStart: 1260)
        #expect(swapped.validationError == .outOfOrder(.evening))
        let equal = defaults.setting(.noon, to: 360)
        #expect(equal.validationError == .outOfOrder(.noon))
        #expect(!equal.isValid)
    }

    @Test func rejectsTimesOffTheQuarterHour() {
        #expect(defaults.setting(.noon, to: 725).validationError == .notOnStep(.noon))
        #expect(defaults.setting(.morning, to: 361).validationError == .notOnStep(.morning))
    }

    @Test func rejectsPartsShorterThan30Minutes() {
        #expect(defaults.setting(.noon, to: 1005).validationError == .tooShort(.noon))  // 16:45–17:00
        #expect(defaults.setting(.noon, to: 375).validationError == .tooShort(.morning))  // 06:00–06:15
        #expect(defaults.setting(.night, to: 1425).validationError == .tooShort(.night))  // 23:45–24:00
        #expect(defaults.setting(.night, to: 1410).isValid)  // 23:30–24:00 is exactly 30 min
        #expect(defaults.setting(.noon, to: 390).isValid)  // 06:00–06:30
    }

    @Test func rejectsTimesOutsideTheDay() {
        #expect(defaults.setting(.morning, to: -15).validationError == .outOfRange(.morning))
        #expect(defaults.setting(.night, to: 1440).validationError == .outOfRange(.night))
    }

    @Test func allowedStartsKeepEveryPartValid() {
        let morning = defaults.allowedStarts(for: .morning)
        #expect(morning.first == 0)
        #expect(morning.last == 690)
        let noon = defaults.allowedStarts(for: .noon)
        #expect(noon.first == 390)
        #expect(noon.last == 990)
        let night = defaults.allowedStarts(for: .night)
        #expect(night.first == 1050)
        #expect(night.last == 1410)
        for part in DayPart.allCases {
            for start in defaults.allowedStarts(for: part) {
                #expect(defaults.setting(part, to: start).isValid)
            }
        }
    }

    @Test func allowedStartsRoundUpToTheStep() {
        // An existing off-step value elsewhere still yields on-step choices.
        let settings = PartSettings(morningStart: 365, noonStart: 720, eveningStart: 1020, nightStart: 1260)
        #expect(settings.allowedStarts(for: .noon).first == 405)
    }

    @Test func partOrder() {
        #expect(DayPart.allCases == [.morning, .noon, .evening, .night])
        #expect(DayPart.morning < .noon)
        #expect(DayPart.morning.next == .noon)
        #expect(DayPart.night.next == nil)
        #expect(DayPart.evening.rawValue == "evening")
    }
}
