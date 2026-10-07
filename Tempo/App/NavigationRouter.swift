import Core
import Foundation
import Observation

/// Which tab is showing and what's presented over it, and where links lead (SPEC F-09, ios.md §11).
@Observable
@MainActor
final class NavigationRouter {
    var selectedTab: AppTab = .today
    /// Set by links to Today; the Today screen scrolls to it and clears it.
    var todayFocus: TodayFocus?
    /// Set by Habit detail's "See all"; the Missed tab filters Earlier to this habit and clears it.
    var missedTaskFilter: UUID?
    /// The missed popup, when it's showing (SPEC F-08).
    var missedPopup: MissedPopupContent?
    /// Occurrences the popup's "Review missed tasks" asked the Missed tab to highlight.
    var missedHighlight: Set<String> = []
    var editor: EditorRequest?
    var isTimerScreenPresented = false
    var taskPicker: TaskPickerRequest?
    var logTime: LogTimeRequest?
    var isSettingsPresented = false
    var isHistoryPresented = false

    /// True when this activation came from a widget, a notification or a pending open action. The missed popup
    /// waits for a normal open (SPEC F-08). Reset when the app goes to the background.
    private(set) var openedFromLinkThisActivation = false

    /// Opens a destination from a link.
    func open(_ link: DeepLink) {
        openedFromLinkThisActivation = true
        dismissPresented()
        switch link {
        case .today(let day, let part, let taskID):
            selectedTab = .today
            todayFocus = TodayFocus(day: day, part: part, taskID: taskID)
        case .newTask(let day, let type):
            editor = .new(day: day, type: type)
        case .missed:
            selectedTab = .missed
        case .timer:
            isTimerScreenPresented = true
        }
    }

    /// Acts on something a widget button asked for before opening the app (SPEC §4.6).
    func handle(_ action: PendingOpenAction) {
        openedFromLinkThisActivation = true
        dismissPresented()
        switch action {
        case .chooseTaskForTimer(let timer):
            taskPicker = TaskPickerRequest(timer: timer)
        }
    }

    func openEditor(_ request: EditorRequest) {
        editor = request
    }

    /// Opens a day in Today from inside the app, for example from the Stats chart (SPEC F-14). Unlike a link,
    /// this isn't an outside open, so it doesn't affect the missed popup.
    func showDay(_ day: DayKey) {
        todayFocus = TodayFocus(day: day, part: nil, taskID: nil)
        selectedTab = .today
    }

    /// Opens the Missed tab with Earlier filtered to one habit (SPEC F-13 "See all").
    func showMissed(for taskID: UUID) {
        missedTaskFilter = taskID
        selectedTab = .missed
    }

    /// "Review missed tasks": switches to the Missed tab and highlights the popup's tasks (SPEC F-08).
    func reviewMissed(_ occurrenceIDs: [String]) {
        missedPopup = nil
        missedHighlight = Set(occurrenceIDs)
        selectedTab = .missed
    }

    func didEnterBackground() {
        openedFromLinkThisActivation = false
    }

    private func dismissPresented() {
        missedPopup = nil
        editor = nil
        isTimerScreenPresented = false
        taskPicker = nil
        logTime = nil
        isSettingsPresented = false
        isHistoryPresented = false
    }
}
