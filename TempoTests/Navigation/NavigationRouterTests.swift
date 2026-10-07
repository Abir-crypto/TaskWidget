import Core
import Foundation
import Testing

@testable import Tempo

@MainActor
struct NavigationRouterTests {
    private let router = NavigationRouter()

    @Test func todayLinkSelectsTodayWithItsFocus() {
        router.selectedTab = .stats
        let taskID = UUID()
        router.open(.today(day: DayKey(rawValue: 20_261_008), part: .noon, taskID: taskID))
        #expect(router.selectedTab == .today)
        #expect(router.todayFocus?.day == DayKey(rawValue: 20_261_008))
        #expect(router.todayFocus?.part == .noon)
        #expect(router.todayFocus?.taskID == taskID)
        #expect(router.openedFromLinkThisActivation)
    }

    @Test func newTaskLinkOpensTheEditorWithPresets() {
        router.open(.newTask(day: DayKey(rawValue: 20_261_008), type: .duration))
        #expect(router.editor?.mode == .new(day: DayKey(rawValue: 20_261_008), type: .duration))
    }

    @Test func missedLinkSelectsTheMissedTab() {
        router.open(.missed)
        #expect(router.selectedTab == .missed)
    }

    @Test func timerLinkOpensTheTimerScreen() {
        router.open(.timer)
        #expect(router.isTimerScreenPresented)
    }

    @Test func pendingActionOpensTheTaskPicker() {
        let timer = FinishedTimer(habitID: nil, day: DayKey(rawValue: 20_261_006), seconds: 1_080)
        router.handle(.chooseTaskForTimer(timer))
        #expect(router.taskPicker?.timer == timer)
        #expect(router.openedFromLinkThisActivation)
    }

    @Test func linksCloseWhateverWasOpen() {
        router.openEditor(.new())
        router.isSettingsPresented = true
        router.open(.missed)
        #expect(router.editor == nil)
        #expect(!router.isSettingsPresented)
    }

    @Test func backgroundResetsTheLinkFlag() {
        router.open(.missed)
        router.didEnterBackground()
        #expect(!router.openedFromLinkThisActivation)
    }

    @Test func normalOpenIsNotFromALink() {
        #expect(!router.openedFromLinkThisActivation)
        router.openEditor(.new())
        #expect(!router.openedFromLinkThisActivation)
    }
}
