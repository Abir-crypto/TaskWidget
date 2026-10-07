import Core
import Foundation
import Testing

@testable import Tempo

struct DeepLinkTests {
    private func link(_ string: String) -> DeepLink {
        DeepLink(url: URL(string: string) ?? URL(filePath: "/"))
    }

    private let taskID = UUID()

    @Test func parsesToday() {
        #expect(link("tempo://today") == .today())
        #expect(link("tempo://today?day=20261008") == .today(day: DayKey(rawValue: 20_261_008)))
        #expect(link("tempo://today?part=noon") == .today(part: .noon))
        #expect(
            link("tempo://today?day=20261006&part=evening&task=\(taskID.uuidString)")
                == .today(day: DayKey(rawValue: 20_261_006), part: .evening, taskID: taskID))
    }

    @Test func parsesNewTask() {
        #expect(link("tempo://new") == .newTask())
        #expect(link("tempo://new?day=20261008") == .newTask(day: DayKey(rawValue: 20_261_008)))
        #expect(link("tempo://new?type=duration") == .newTask(type: .duration))
        #expect(
            link("tempo://new?day=20261008&type=one_time")
                == .newTask(day: DayKey(rawValue: 20_261_008), type: .oneTime))
    }

    @Test func parsesMissedAndTimer() {
        #expect(link("tempo://missed") == .missed)
        #expect(link("tempo://timer") == .timer)
    }

    @Test func unknownOrMalformedOpensToday() {
        #expect(link("tempo://somewhere") == .today())
        #expect(link("https://example.com/today") == .today())
        #expect(link("tempo://") == .today())
        #expect(link("tempo://today?part=lunch&task=nope&day=soon") == .today())
        #expect(link("tempo://new?type=weekly") == .newTask())
    }

    @Test func buildsURLsThatParseBack() {
        let links: [DeepLink] = [
            .today(), .today(day: DayKey(rawValue: 20_261_006), part: .night, taskID: taskID),
            .newTask(), .newTask(day: DayKey(rawValue: 20_261_008), type: .progress), .missed, .timer,
        ]
        for link in links {
            #expect(DeepLink(url: link.url) == link)
        }
        #expect(DeepLink.missed.url.absoluteString == "tempo://missed")
        #expect(DeepLink.today(part: .noon).url.absoluteString == "tempo://today?part=noon")
    }
}
