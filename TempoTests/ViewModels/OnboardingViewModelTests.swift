import Core
import Foundation
import Testing

@testable import Tempo

/// SPEC T-28: the guide's pages, Skip, the part times on page 6, and page 7's notification choice.
@MainActor
struct OnboardingViewModelTests {
    private let clock = TestEnvironment.clock()
    private let store: SwiftDataTaskStore
    private let deviceState = TestEnvironment.deviceState()
    private let notifications = FixedNotificationScheduler(permission: .notDetermined)

    init() throws {
        store = try TestEnvironment.store(clock: clock)
    }

    private func model(_ mode: GuideMode) -> OnboardingViewModel {
        OnboardingViewModel(
            mode: mode, deviceState: deviceState, notifications: notifications,
            reminders: ReminderManager(store: store, deviceState: deviceState, scheduler: notifications, clock: clock))
    }

    @Test func firstLaunchHasSevenPagesAndSkipLeadsToTheSetup() {
        let model = model(.firstLaunch)
        #expect(model.pages == OnboardingPage.allCases)
        #expect(model.page == .welcome)
        for page in OnboardingPage.allCases {
            model.page = page
            #expect(model.showsSkip == page.isIntroduction, "Skip on \(page)")
        }
        model.page = .widgets
        model.skip()
        #expect(model.page == .partsOfTheDay)
        model.next()
        #expect(model.page == .notifications)
        #expect(model.nextPage == nil)
    }

    @Test func nextGoesThroughThePagesInOrder() {
        let model = model(.firstLaunch)
        var seen = [model.page]
        while model.nextPage != nil {
            model.next()
            seen.append(model.page)
        }
        #expect(seen == OnboardingPage.allCases)
    }

    @Test func pageSixSavesThePartTimes() async throws {
        let parts = SettingsViewModel(
            manager: SettingsManager(store: store, refresh: RefreshManager(widgets: WidgetReloadCounter())),
            notifications: notifications)
        await parts.load()
        #expect(parts.settings.parts == .defaults)
        parts.setStart(of: .morning, to: 420)
        parts.setStart(of: .evening, to: 1080)
        let saved = try #require(try store.settings())
        #expect(saved.parts.morningStart == 420)
        #expect(saved.parts.eveningStart == 1080)
    }

    @Test func allowAsksForPermissionSchedulesAndClosesForGood() async {
        let model = model(.firstLaunch)
        model.page = .notifications
        await model.allowNotifications()
        #expect(await notifications.permission() == .allowed)
        #expect(notifications.replaceCount > 0)
        #expect(deviceState.guideCompleted)
    }

    @Test func notNowClosesForGoodWithoutAsking() async {
        let model = model(.firstLaunch)
        model.page = .notifications
        model.finish()
        #expect(await notifications.permission() == .notDetermined)
        #expect(deviceState.guideCompleted)
    }

    @Test func howToUseShowsPagesOneToFive() {
        let model = model(.howToUse)
        #expect(model.pages == [.welcome, .taskKinds, .reminders, .widgets, .missedAndStats])
        #expect(!model.showsSkip)
        model.page = .missedAndStats
        #expect(model.nextPage == nil)
        model.finish()
        #expect(!deviceState.guideCompleted)
    }
}
