import Testing

@testable import Core

struct TaskRulesTests {
    @Test func titlesAreTrimmedAndLimited() {
        #expect(TaskRules.normalizedTitle("  Read  ") == "Read")
        #expect(TaskRules.titleError("   ") == .emptyTitle)
        #expect(TaskRules.titleError("") == .emptyTitle)
        #expect(TaskRules.titleError(String(repeating: "a", count: 100)) == nil)
        #expect(TaskRules.titleError(" " + String(repeating: "a", count: 100) + " ") == nil)
        #expect(TaskRules.titleError(String(repeating: "a", count: 101)) == .titleTooLong)
    }

    @Test func fixedTimesUseFiveMinuteSteps() {
        #expect(TaskRules.timingError(.fixed(minute: 750)) == nil)
        #expect(TaskRules.timingError(.fixed(minute: 0)) == nil)
        #expect(TaskRules.timingError(.fixed(minute: 1435)) == nil)
        #expect(TaskRules.timingError(.fixed(minute: 752)) == .invalidFixedTime)
        #expect(TaskRules.timingError(.fixed(minute: 1440)) == .invalidFixedTime)
        #expect(TaskRules.timingError(.fixed(minute: -5)) == .invalidFixedTime)
        #expect(TaskRules.timingError(.part(.noon)) == nil)
        #expect(TaskRules.timingError(.anytime) == nil)
    }

    @Test func targetsOnlyForDurationHabits() {
        #expect(TaskRules.targetError(30, type: .duration) == nil)
        #expect(TaskRules.targetError(5, type: .duration) == nil)
        #expect(TaskRules.targetError(480, type: .duration) == nil)
        #expect(TaskRules.targetError(0, type: .duration) == .invalidTarget)
        #expect(TaskRules.targetError(485, type: .duration) == .invalidTarget)
        #expect(TaskRules.targetError(32, type: .duration) == .invalidTarget)
        #expect(TaskRules.targetError(nil, type: .duration) == .invalidTarget)
        #expect(TaskRules.targetError(nil, type: .progress) == nil)
        #expect(TaskRules.targetError(30, type: .progress) == .invalidTarget)
    }

    @Test func lengthsAreOneTo365Days() {
        #expect(TaskRules.lengthError(nil) == nil)
        #expect(TaskRules.lengthError(1) == nil)
        #expect(TaskRules.lengthError(365) == nil)
        #expect(TaskRules.lengthError(0) == .invalidLength)
        #expect(TaskRules.lengthError(366) == .invalidLength)
    }

    @Test func habitsNeedAWeekday() {
        #expect(TaskRules.weekdaysError(.none, type: .progress) == .noWeekdays)
        #expect(TaskRules.weekdaysError([.monday], type: .duration) == nil)
        #expect(TaskRules.weekdaysError(.none, type: .oneTime) == nil)
        #expect(TaskRules.weekdaysError(Weekdays(rawValue: 128), type: .progress) == .noWeekdays)
    }
}
