import Core
import Foundation

/// What the Day widget shows (SPEC F-19): four columns, an Anytime footer, and the empty and free states.
struct DayWidgetContent: Hashable {
    let columns: [DayColumn]
    /// Anytime tasks still open ("Anytime · N left"); 0 hides the footer.
    let anytimeLeft: Int
    /// Today has no tasks: "No tasks today", and tapping opens the editor for today.
    let hasNoTasks: Bool
    /// Every task is done: "You're free today".
    let isAllDone: Bool

    init(snapshot: WidgetSnapshot, at date: Date) {
        let plan = snapshot.plan(at: date)
        columns = plan.sections.filter { $0.part != nil }.map(DayColumn.init)
        anytimeLeft = plan.section(for: nil)?.leftCount ?? 0
        hasNoTasks = plan.isEmpty
        isAllDone = !plan.isEmpty && plan.items.allSatisfy { $0.status == .done }
    }
}
