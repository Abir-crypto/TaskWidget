import Core
import Foundation

/// What the Focus widget shows (SPEC F-20): the next-task rule's result and the one after it, or the free state.
enum FocusWidgetContent: Hashable {
    case next(FocusItem, then: FocusItem?)
    /// Nothing left today. `allDoneCount` is how many tasks today had, when every one of them is done (D-091).
    case free(allDoneCount: Int?)

    init(snapshot: WidgetSnapshot, at date: Date) {
        let core = snapshot.core
        guard let next = NextTaskRule.next(in: core, now: date) else {
            let plan = snapshot.plan(at: date)
            let allDone = !plan.isEmpty && plan.items.allSatisfy { $0.status == .done }
            self = .free(allDoneCount: allDone ? plan.items.count : nil)
            return
        }
        self = .next(
            FocusItem(next, snapshot: core),
            then: NextTaskRule.then(in: core, now: date).map { FocusItem($0, snapshot: core) })
    }

    /// Where tapping leads: the task shown, or Today.
    var url: URL {
        if case .next(let item, _) = self { return item.url }
        return DeepLink.today().url
    }
}
