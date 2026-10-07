import Foundation
import Testing

@testable import Core

struct TimerRulesTests {
    private let calendar = TestCalendar.london
    private let start = TestCalendar.today(10)
    private let habitID = UUID()

    private func minutes(_ value: Double) -> TimeInterval { value * 60 }

    @Test func startsRunningOnTheCurrentDay() {
        let timer = TimerRules.start(kind: .habit, habitID: habitID, now: start, calendar: calendar)
        #expect(timer.kind == .habit)
        #expect(timer.habitID == habitID)
        #expect(timer.startDay == TestCalendar.today)
        #expect(TimerRules.isRunning(timer))
        #expect(TimerRules.elapsed(timer, now: start.addingTimeInterval(90)) == 90)
    }

    @Test func genericTimersHaveNoHabit() {
        let timer = TimerRules.start(kind: .generic, habitID: habitID, now: start, calendar: calendar)
        #expect(timer.habitID == nil)
    }

    @Test func pausedTimeIsNotCounted() {
        var timer = TimerRules.start(kind: .generic, habitID: nil, now: start, calendar: calendar)
        timer = TimerRules.pause(timer, now: start.addingTimeInterval(minutes(10)))
        #expect(!TimerRules.isRunning(timer))
        #expect(TimerRules.elapsed(timer, now: start.addingTimeInterval(minutes(60))) == minutes(10))
        timer = TimerRules.resume(timer, now: start.addingTimeInterval(minutes(60)))
        timer = TimerRules.pause(timer, now: start.addingTimeInterval(minutes(65)))
        timer = TimerRules.resume(timer, now: start.addingTimeInterval(minutes(90)))
        #expect(TimerRules.elapsed(timer, now: start.addingTimeInterval(minutes(100))) == minutes(25))
    }

    @Test func pausingTwiceOrResumingARunningTimerChangesNothing() {
        let running = TimerRules.start(kind: .generic, habitID: nil, now: start, calendar: calendar)
        #expect(TimerRules.resume(running, now: start.addingTimeInterval(60)) == running)
        let paused = TimerRules.pause(running, now: start.addingTimeInterval(60))
        #expect(TimerRules.pause(paused, now: start.addingTimeInterval(120)) == paused)
    }

    @Test func timeFreezesAtDone() {
        let timer = TimerRules.start(kind: .habit, habitID: habitID, now: start, calendar: calendar)
        let finished = TimerRules.finish(timer, now: start.addingTimeInterval(minutes(18) + 30))
        #expect(finished.seconds == 18 * 60 + 30)
        #expect(finished.habitID == habitID)
        #expect(finished.day == TestCalendar.today)
    }

    @Test func underOneMinuteIsNotSaved() {
        let timer = TimerRules.start(kind: .generic, habitID: nil, now: start, calendar: calendar)
        #expect(!TimerRules.shouldSave(TimerRules.finish(timer, now: start.addingTimeInterval(59))))
        #expect(TimerRules.shouldSave(TimerRules.finish(timer, now: start.addingTimeInterval(60))))
    }

    @Test func timeAfterMidnightGoesToTheDayItStarted() {
        let lateStart = TestCalendar.date(2026, 10, 6, 23, 40)
        let timer = TimerRules.start(kind: .habit, habitID: habitID, now: lateStart, calendar: calendar)
        let finished = TimerRules.finish(timer, now: TestCalendar.date(2026, 10, 7, 0, 20))
        #expect(finished.day == TestCalendar.today)
        #expect(finished.seconds == 40 * 60)
    }

    @Test func clockMovedBackNeverCountsBelowZero() {
        let timer = TimerRules.start(kind: .generic, habitID: nil, now: start, calendar: calendar)
        #expect(TimerRules.elapsed(timer, now: start.addingTimeInterval(-300)) == 0)
    }

    @Test func alertFollowsTheLastStartOrResume() {
        var timer = TimerRules.start(kind: .habit, habitID: habitID, now: start, calendar: calendar)
        #expect(TimerRules.nextAlert(timer, periodMinutes: 120, now: start) == start.addingTimeInterval(minutes(120)))
        // "Keep going": after the first alert, the next comes one period later.
        #expect(
            TimerRules.nextAlert(timer, periodMinutes: 120, now: start.addingTimeInterval(minutes(121)))
                == start.addingTimeInterval(minutes(240)))
        // Pausing cancels it; resuming starts a new count.
        timer = TimerRules.pause(timer, now: start.addingTimeInterval(minutes(30)))
        #expect(TimerRules.nextAlert(timer, periodMinutes: 120, now: start.addingTimeInterval(minutes(31))) == nil)
        let resume = start.addingTimeInterval(minutes(45))
        timer = TimerRules.resume(timer, now: resume)
        #expect(TimerRules.nextAlert(timer, periodMinutes: 120, now: resume) == resume.addingTimeInterval(minutes(120)))
        #expect(TimerRules.nextAlert(timer, periodMinutes: 60, now: resume) == resume.addingTimeInterval(minutes(60)))
    }

    @Test func stateSurvivesEncoding() throws {
        let timer = TimerRules.pause(
            TimerRules.start(kind: .habit, habitID: habitID, now: start, calendar: calendar),
            now: start.addingTimeInterval(125))
        let decoded = try JSONDecoder().decode(TimerState.self, from: JSONEncoder().encode(timer))
        #expect(decoded == timer)
        #expect(TimerRules.elapsed(decoded, now: start.addingTimeInterval(999)) == 125)
    }
}
