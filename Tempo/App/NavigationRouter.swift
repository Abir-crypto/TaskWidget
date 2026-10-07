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
    var editor: EditorRequest?
    var isTimerScreenPresented = false
    var taskPicker: TaskPickerRequest?
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

    func didEnterBackground() {
        openedFromLinkThisActivation = false
    }

    private func dismissPresented() {
        editor = nil
        isTimerScreenPresented = false
        taskPicker = nil
        isSettingsPresented = false
        isHistoryPresented = false
    }
}
