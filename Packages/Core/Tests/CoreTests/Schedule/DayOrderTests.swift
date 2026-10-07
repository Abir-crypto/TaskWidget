import Testing

@testable import Core

struct DayOrderTests {
    @Test func partsThenFixedTimesThenCreationOrder() {
        var fixtures = Fixtures()
        let anytime = fixtures.oneTime("Anytime", timing: .anytime)
        let evening = fixtures.oneTime("Evening", timing: .part(.evening))
        let noonPart = fixtures.oneTime("Noon part", timing: .part(.noon))
        let noonLate = fixtures.oneTime("16:00", timing: .fixed(minute: 960))
        let noonEarly = fixtures.oneTime("12:30", timing: .fixed(minute: 750))
        let noonPart2 = fixtures.habit("Noon part 2", timing: .part(.noon))
        let early = fixtures.oneTime("05:00", timing: .fixed(minute: 300))
        let night = fixtures.oneTime("Night", timing: .part(.night))
        let sorted = DayOrder.sorted(fixtures.engine.occurrences(on: TestCalendar.today), parts: .defaults)
        #expect(
            sorted.map(\.task.id) == [
                early.id, noonEarly.id, noonLate.id, noonPart.id, noonPart2.id, evening.id, night.id, anytime.id,
            ])
    }
}
