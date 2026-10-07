import Foundation
import Testing

@testable import Core

struct DurationMathTests {
    private func math(_ fixtures: Fixtures) -> DurationMath {
        DurationMath(snapshot: fixtures.snapshot())
    }

    @Test func minutesAreTheFloorOfTheSeconds() {
        var fixtures = Fixtures()
        let task = fixtures.duration()
        fixtures.log(task, minutes: 0, on: TestCalendar.today, seconds: 3_599)
        #expect(math(fixtures).minutes(taskID: task.id, day: TestCalendar.today) == 59)
        fixtures.log(task, minutes: 0, on: TestCalendar.today, seconds: 1)
        #expect(math(fixtures).minutes(taskID: task.id, day: TestCalendar.today) == 60)
    }

    @Test func minutesSumEveryEntryOfTheDay() {
        var fixtures = Fixtures()
        let task = fixtures.duration()
        fixtures.log(task, minutes: 10, on: TestCalendar.today, seconds: 30)
        fixtures.log(task, minutes: 5, on: TestCalendar.today, seconds: 30)
        fixtures.log(task, minutes: 99, on: TestCalendar.oct(5))
        #expect(math(fixtures).minutes(taskID: task.id, day: TestCalendar.today) == 16)
    }

    @Test func specExampleMeetsTheWeeklyGoal() throws {
        // Target 30 on Mon, Wed and Fri: goal 90. Mon 50, Wed 0, Fri 45, Sat 20 → 115, met. Wednesday is still Missed.
        var fixtures = Fixtures()
        let task = fixtures.duration(timing: .part(.evening), weekdays: [.monday, .wednesday, .friday], target: 30)
        fixtures.log(task, minutes: 50, on: TestCalendar.oct(5))
        fixtures.log(task, minutes: 45, on: TestCalendar.oct(9))
        fixtures.log(task, minutes: 20, on: TestCalendar.oct(10))
        let progress = math(fixtures).weeklyProgress(of: task, containing: TestCalendar.oct(7))
        #expect(progress.goal == 90)
        #expect(progress.minutes == 115)
        #expect(progress.isMet)
        #expect(fixtures.status(task, on: TestCalendar.oct(7), at: TestCalendar.date(2026, 10, 12, 9)) == .missed)
    }

    @Test func targetChangedMidWeekAddsUpDayByDay() {
        var fixtures = Fixtures()
        let task = fixtures.duration(weekdays: [.monday, .wednesday, .friday], target: 30)
        fixtures.reschedule(task, from: TestCalendar.oct(7), target: 45)
        let progress = math(fixtures).weeklyProgress(of: task, containing: TestCalendar.oct(6))
        #expect(progress.goal == 30 + 45 + 45)
    }

    @Test func weekdaysChangedMidWeekUseEachDaysSchedule() {
        var fixtures = Fixtures()
        let task = fixtures.duration(weekdays: [.monday, .tuesday], target: 30)
        fixtures.reschedule(task, from: TestCalendar.oct(7), weekdays: [.friday, .saturday])
        // Mon, Tue under the old schedule; Fri, Sat under the new one.
        #expect(math(fixtures).weeklyProgress(of: task, containing: TestCalendar.today).goal == 120)
    }

    @Test func weekOnlyCountsDaysFromTheStart() {
        var fixtures = Fixtures()
        let task = fixtures.duration(weekdays: .all, start: TestCalendar.oct(8), target: 30)  // Thu
        fixtures.log(task, minutes: 30, on: TestCalendar.oct(8))
        let progress = math(fixtures).weeklyProgress(of: task, containing: TestCalendar.oct(8))
        #expect(progress.goal == 4 * 30)  // Thu–Sun
        #expect(progress.minutes == 30)
    }

    @Test func weekStopsAtTheLastDay() {
        var fixtures = Fixtures()
        let task = fixtures.habit(
            type: .duration, weekdays: .all, start: TestCalendar.oct(1), endedOn: TestCalendar.oct(7), target: 30)
        fixtures.log(task, minutes: 10, on: TestCalendar.oct(8))  // after the last day; never counted
        let progress = math(fixtures).weeklyProgress(of: task, containing: TestCalendar.oct(6))
        #expect(progress.goal == 3 * 30)  // Mon–Wed
        #expect(progress.minutes == 0)
    }

    @Test func unscheduledDaysCountTowardTheTotalOnly() {
        var fixtures = Fixtures()
        let task = fixtures.duration(weekdays: [.monday], target: 30)
        fixtures.log(task, minutes: 25, on: TestCalendar.oct(6))  // Tuesday, not scheduled
        let math = math(fixtures)
        #expect(math.weeklyProgress(of: task, containing: TestCalendar.today) == GoalProgress(minutes: 25, goal: 30))
        #expect(
            math.scheduledDays(of: task, from: TestCalendar.oct(5), through: TestCalendar.oct(11)) == [
                TestCalendar.oct(5)
            ])
        #expect(math.liveDays(of: task, from: TestCalendar.oct(5), through: TestCalendar.oct(11)).count == 7)
    }

    @Test func weekFollowsTheRegion() {
        var fixtures = Fixtures()
        let task = fixtures.duration(weekdays: .all, start: TestCalendar.oct(1), target: 30)
        var sundayFirst = TestCalendar.london
        sundayFirst.firstWeekday = 1
        let snapshot = Snapshot(data: fixtures.data, settings: .defaults, calendar: sundayFirst)
        let week = DurationMath(snapshot: snapshot).week(containing: TestCalendar.today)
        #expect(week.first == TestCalendar.oct(4))
        #expect(week.last == TestCalendar.oct(10))
        #expect(DurationMath(snapshot: snapshot).weeklyProgress(of: task, containing: TestCalendar.today).goal == 210)
    }

    @Test func logTimeRule() {
        #expect(TaskRules.logTimeError(5) == nil)
        #expect(TaskRules.logTimeError(480) == nil)
        #expect(TaskRules.logTimeError(0) == .invalidLogTime)
        #expect(TaskRules.logTimeError(7) == .invalidLogTime)
        #expect(TaskRules.logTimeError(485) == .invalidLogTime)
    }
}
