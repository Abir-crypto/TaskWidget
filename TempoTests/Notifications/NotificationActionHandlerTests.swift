import Core
import Foundation
import Testing
import UserNotifications

@testable import Tempo

@MainActor
struct NotificationActionHandlerTests {
    private let clock = TestEnvironment.clock(hour: 9)
    private let scheduler = FixedNotificationScheduler(permission: .allowed)
    private let dependencies: AppDependencies
    private let router = NavigationRouter()

    init() throws {
        dependencies = AppDependencies(
            clock: clock, store: try TestEnvironment.store(clock: clock), deviceState: TestEnvironment.deviceState(),
            notifications: scheduler, widgets: WidgetReloadCounter())
        dependencies.prepare()
    }

    private func tap(_ link: DeepLink) {
        NotificationActionHandler.handle(
            NotificationResponse(actionIdentifier: UNNotificationDefaultActionIdentifier, url: link.url),
            dependencies: dependencies, router: router)
    }

    @Test func tappingOpensEachDestination() {
        tap(.today(day: TestEnvironment.today, part: .noon))
        #expect(router.selectedTab == .today)
        #expect(router.todayFocus?.part == .noon)
        tap(.missed)
        #expect(router.selectedTab == .missed)
        tap(.timer)
        #expect(router.isTimerScreenPresented)
        #expect(router.openedFromLinkThisActivation)
    }

    @Test func stopPausesTheTimerAndOpensTheTimerScreen() throws {
        try dependencies.timer.startGenericTimer()
        NotificationActionHandler.handle(
            NotificationResponse(actionIdentifier: "STOP", url: DeepLink.timer.url), dependencies: dependencies,
            router: router)
        #expect(dependencies.timer.isRunning == false)
        #expect(dependencies.timer.state != nil)
        #expect(router.isTimerScreenPresented)
    }

    @Test func keepGoingSchedulesTheNextAlert() async throws {
        try dependencies.timer.startGenericTimer()
        clock.advance(by: 7_300)  // past the first alert
        NotificationActionHandler.handle(
            NotificationResponse(actionIdentifier: "KEEP_GOING", url: DeepLink.timer.url), dependencies: dependencies,
            router: router)
        #expect(dependencies.timer.isRunning)
        #expect(
            await eventually {
                scheduler.pending.contains { $0.id == "timer-alert" && $0.body == "It's been running for 4 hours." }
            })
    }
}
