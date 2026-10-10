import Core
import Foundation

/// What the Lock Screen widgets show (SPEC F-22): the next-task rule's result, or the free state.
enum LockScreenWidgetContent: Hashable {
    case next(LockScreenItem)
    /// Nothing left today. `allDoneCount` is how many tasks today had, when every one of them is done (D-091).
    case free(allDoneCount: Int?)

    init(snapshot: WidgetSnapshot, at date: Date) {
        let core = snapshot.core
        guard let next = NextTaskRule.next(in: core, now: date) else {
            self = .free(allDoneCount: snapshot.allDoneCount(at: date))
            return
        }
        self = .next(LockScreenItem(NextTaskItem(next, snapshot: core), hidesTitle: core.settings.hideLockScreenTitles))
    }

    /// Where tapping leads: the task shown, or Today.
    var url: URL {
        if case .next(let item) = self { return item.url }
        return DeepLink.today().url
    }
}
