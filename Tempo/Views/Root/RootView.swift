import SwiftUI

/// The four tabs, what's presented over them, and where links lead (SPEC F-09).
struct RootView: View {
    let dependencies: AppDependencies
    @Bindable var router: NavigationRouter
    @State private var model: RootViewModel
    @State private var timerController: TimerController
    /// The popup content on screen, kept so it can be marked seen when the popup closes.
    @State private var shownPopup: MissedPopupContent?
    @Environment(\.scenePhase) private var scenePhase

    init(dependencies: AppDependencies, router: NavigationRouter) {
        self.dependencies = dependencies
        self.router = router
        _model = State(initialValue: RootViewModel(missed: dependencies.missed))
        _timerController = State(initialValue: TimerController(dependencies: dependencies, router: router))
    }

    var body: some View {
        TabView(selection: $router.selectedTab) {
            TodayView(dependencies: dependencies, router: router)
                .tabItem { Label(AppTab.today.title, systemImage: AppTab.today.systemImage) }
                .tag(AppTab.today)
            TasksView(dependencies: dependencies, router: router)
                .tabItem { Label(AppTab.tasks.title, systemImage: AppTab.tasks.systemImage) }
                .tag(AppTab.tasks)
            MissedView(dependencies: dependencies, router: router)
                .tabItem { Label(AppTab.missed.title, systemImage: AppTab.missed.systemImage) }
                .tag(AppTab.missed)
                .badge(model.missedCount)
            StatsView(dependencies: dependencies, router: router)
                .tabItem { Label(AppTab.stats.title, systemImage: AppTab.stats.systemImage) }
                .tag(AppTab.stats)
        }
        .background {
            // The badge changes at part boundaries, so it's recounted every minute (ios.md §4, rule 4).
            TimelineView(.everyMinute) { context in
                Color.clear.task(id: context.date) { model.load() }
            }
        }
        .task(id: dependencies.refresh.revision) {
            model.load()
            timerController.load()
        }
        .sheet(item: $router.editor, onDismiss: { router.editorDidClose() }) { request in
            TaskEditorView(dependencies: dependencies, request: request)
        }
        .sheet(isPresented: $router.isTimerScreenPresented) {
            TimerScreenView(dependencies: dependencies)
        }
        .sheet(item: $router.taskPicker) { request in
            TaskPickerView(dependencies: dependencies, request: request)
        }
        .sheet(item: $router.logTime) { request in
            LogTimeView(dependencies: dependencies, taskID: request.taskID)
        }
        .environment(timerController)
        // A new day or a new time zone changes every status and reminder (SPEC §6, ios.md §10).
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            timeChanged()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
            timeChanged()
        }
        // The Timer widget's Done can run inside the app after it's already active (ios.md §11).
        .onReceive(NotificationCenter.default.publisher(for: .pendingOpenActionWritten)) { _ in
            handlePendingOpenAction()
        }
        .onOpenURL { url in
            // Before the first-launch guide is finished, a link waits for it (D-095).
            let link = DeepLink(url: url)
            if dependencies.deviceState.guideCompleted {
                router.open(link)
            } else {
                router.openAfterGuide(link)
            }
        }
        .fullScreenCover(item: $router.guide, onDismiss: guideDidClose) { mode in
            OnboardingView(dependencies: dependencies, mode: mode)
        }
        // The guide shows once, on first launch (SPEC F-23).
        .task {
            if !dependencies.deviceState.guideCompleted { router.guide = .firstLaunch }
        }
        .sheet(item: $router.missedPopup, onDismiss: markPopupSeen) { content in
            MissedPopupView(
                content: content,
                onReview: { router.reviewMissed(content.occurrenceIDs) },
                onNotNow: { router.missedPopup = nil })
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            switch phase {
            case .active:
                handlePendingOpenAction()
                // A widget may have changed data while the app was in the background.
                dependencies.refresh.dataMayHaveChanged()
                Task { await dependencies.reminders.rebuild() }
                showMissedPopupIfNeeded()
            case .background:
                router.didEnterBackground()
            default:
                break
            }
        }
    }

    /// Acts on what a widget button left for the app, such as choosing a task for a finished timer (SPEC §4.6).
    /// It waits until the first-launch guide is finished (D-095).
    private func handlePendingOpenAction() {
        guard dependencies.deviceState.guideCompleted,
            let action = dependencies.deviceState.pendingOpenAction
        else { return }
        dependencies.deviceState.pendingOpenAction = nil
        router.handle(action)
    }

    /// Opens whatever waited for the guide: a link, or a widget button's pending action.
    private func guideDidClose() {
        router.guideDidClose()
        handlePendingOpenAction()
    }

    private func timeChanged() {
        dependencies.refresh.dataMayHaveChanged()
        Task { await dependencies.reminders.rebuild() }
    }

    /// Shows the missed popup on a normal open, when today has missed tasks it hasn't shown (SPEC F-08).
    /// A link from a widget or notification can arrive slightly after the app becomes active, so it waits
    /// briefly first (ios.md §11).
    private func showMissedPopupIfNeeded() {
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard router.missedPopup == nil, router.guide == nil else { return }
            let items = dependencies.missed.popupItems(openedFromLink: router.openedFromLinkThisActivation)
            guard !items.isEmpty else { return }
            shownPopup = MissedPopupContent(items: items)
            router.missedPopup = shownPopup
        }
    }

    /// Either button, or swiping the popup away, counts as having seen its tasks (SPEC F-08, D-082).
    private func markPopupSeen() {
        guard let shownPopup else { return }
        dependencies.missed.markSeen(shownPopup.occurrenceIDs)
        self.shownPopup = nil
    }
}

#Preview {
    let dependencies = AppDependencies.preview(hour: 13, sample: true)
    let router = NavigationRouter()
    return RootView(dependencies: dependencies, router: router).environment(router)
}
