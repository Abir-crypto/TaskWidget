import Foundation

/// The guide's seven pages, in order (SPEC F-23).
enum OnboardingPage: Int, CaseIterable, Identifiable {
    case welcome
    case taskKinds
    case reminders
    case widgets
    case missedAndStats
    case partsOfTheDay
    case notifications

    var id: Int { rawValue }

    /// Pages 1–5 introduce the app. They have Skip, and How to use shows only these.
    var isIntroduction: Bool { rawValue < Self.partsOfTheDay.rawValue }

    var systemImage: String {
        switch self {
        case .welcome: "sun.horizon"
        case .taskKinds: "checklist"
        case .reminders: "bell.badge"
        case .widgets: "square.grid.2x2"
        case .missedAndStats: "chart.bar"
        case .partsOfTheDay: "clock"
        case .notifications: "bell"
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .welcome: "Welcome to Tempo"
        case .taskKinds: "Three kinds of tasks"
        case .reminders: "Reminders"
        case .widgets: "Widgets"
        case .missedAndStats: "Missed and Stats"
        case .partsOfTheDay: "Your parts of the day"
        case .notifications: "Notifications"
        }
    }

    var message: LocalizedStringResource {
        switch self {
        case .welcome:
            "Plan your day by its parts: morning, noon, evening and night. Every task belongs to a part, a set time, or anytime."
        case .taskKinds:
            "One-time tasks are done once. Progress habits are checked off on their days, and duration habits count minutes toward a daily target."
        case .reminders:
            "A summary as each part starts, a reminder before it ends, and a look at anything you missed."
        case .widgets:
            "Timer runs a stopwatch, Day shows the whole day, Focus shows what's next, and Now lets you check tasks off. On the Lock Screen, you'll see your next task."
        case .missedAndStats:
            "Missed gathers what slipped by, so you can still do it or move it to tomorrow. Stats shows your streaks and how each part of the day is going."
        case .partsOfTheDay:
            "Choose when each part starts. You can change these later in Settings."
        case .notifications:
            "Allow notifications for part summaries, reminders and an end-of-day recap."
        }
    }
}
