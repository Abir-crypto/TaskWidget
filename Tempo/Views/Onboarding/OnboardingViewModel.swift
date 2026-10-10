import Foundation
import Observation

/// State for the first-launch guide and How to use (SPEC F-23).
@Observable
@MainActor
final class OnboardingViewModel {
    let mode: GuideMode
    var page: OnboardingPage = .welcome

    private let deviceState: DeviceState
    private let notifications: any NotificationScheduling
    private let reminders: ReminderManager

    init(
        mode: GuideMode, deviceState: DeviceState, notifications: any NotificationScheduling,
        reminders: ReminderManager
    ) {
        self.mode = mode
        self.deviceState = deviceState
        self.notifications = notifications
        self.reminders = reminders
    }

    /// Every page on first launch; pages 1–5 for How to use.
    var pages: [OnboardingPage] {
        switch mode {
        case .firstLaunch: OnboardingPage.allCases
        case .howToUse: OnboardingPage.allCases.filter(\.isIntroduction)
        }
    }

    /// The page after the current one, or `nil` on the last.
    var nextPage: OnboardingPage? {
        pages.first { $0.rawValue == page.rawValue + 1 }
    }

    /// Skip shows on pages 1–5 of the first-launch guide.
    var showsSkip: Bool { mode == .firstLaunch && page.isIntroduction }

    func next() {
        if let nextPage { page = nextPage }
    }

    /// Jumps to page 6, so the setup pages are never skipped.
    func skip() {
        page = .partsOfTheDay
    }

    /// Page 7's Allow: asks for the system permission, schedules the reminders if it's given, and finishes.
    func allowNotifications() async {
        _ = await notifications.requestPermission()
        await reminders.rebuild()
        finish()
    }

    /// Closes the guide for good after first launch. How to use changes nothing.
    func finish() {
        if mode == .firstLaunch { deviceState.guideCompleted = true }
    }
}
