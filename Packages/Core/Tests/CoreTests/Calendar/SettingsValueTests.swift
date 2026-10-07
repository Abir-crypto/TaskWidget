import Testing

@testable import Core

struct SettingsValueTests {
    @Test func defaultsAreValid() {
        let settings = SettingsValue.defaults
        #expect(settings.validationError == nil)
        #expect(settings.endingSoonLead == 30)
        #expect(settings.fixedLead == 10)
        #expect(settings.recapMinute == 1410)
        #expect(settings.timerAlertMinutes == 120)
        #expect(settings.notifyPartStart && settings.notifyEndingSoon && settings.notifyFixed)
        #expect(settings.notifyRecap && settings.notifyTimer)
        #expect(!settings.hideLockScreenTitles)
    }

    @Test func recapChoicesRunFromNightTo2345() {
        let choices = SettingsValue.defaults.recapChoices
        #expect(choices.first == 1260)
        #expect(choices.last == 1425)
        #expect(choices.count == 12)
        var late = SettingsValue.defaults
        late.parts = late.parts.setting(.night, to: 1410)
        #expect(late.recapChoices == [1410, 1425])
    }

    @Test func rejectsValuesOutsideTheirChoices() {
        var settings = SettingsValue.defaults
        settings.endingSoonLead = 20
        #expect(settings.validationError == .endingSoonLead)
        settings = .defaults
        settings.fixedLead = 20
        #expect(settings.validationError == .fixedLead)
        settings = .defaults
        settings.timerAlertMinutes = 90
        #expect(settings.validationError == .timerAlert)
        settings = .defaults
        settings.recapMinute = 1200  // before Night
        #expect(settings.validationError == .recapMinute)
        settings.recapMinute = 1415  // off the step
        #expect(settings.validationError == .recapMinute)
        settings.recapMinute = 1440
        #expect(settings.validationError == .recapMinute)
        settings = .defaults
        settings.parts = settings.parts.setting(.noon, to: 365)
        #expect(settings.validationError == .parts(.notOnStep(.noon)))
    }

    @Test func recapFollowsNightWhenNightMovesPastIt() {
        var settings = SettingsValue.defaults
        settings.recapMinute = 1290  // 21:30
        settings.parts = settings.parts.setting(.night, to: 1320)  // Night from 22:00
        #expect(settings.validationError == .recapMinute)
        let fixed = settings.keepingRecapInRange()
        #expect(fixed.recapMinute == 1320)
        #expect(fixed.validationError == nil)
        #expect(SettingsValue.defaults.keepingRecapInRange() == .defaults)
    }
}
