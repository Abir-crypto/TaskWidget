import Foundation
import Testing

@testable import Tempo

@MainActor
struct RefreshManagerTests {
    @Test func burstsOfChangesRefreshOnce() async throws {
        let widgets = WidgetReloadCounter()
        let refresh = RefreshManager(widgets: widgets)
        refresh.afterChange()
        refresh.afterChange()
        refresh.afterChange()
        #expect(widgets.count == 0)
        #expect(await eventually { widgets.count == 1 })
        // No second reload follows.
        try await Task.sleep(for: .milliseconds(700))
        #expect(widgets.count == 1)
    }

    @Test func refreshNowIsImmediate() {
        let widgets = WidgetReloadCounter()
        let refresh = RefreshManager(widgets: widgets)
        refresh.refreshNow()
        #expect(widgets.count == 1)
    }
}
