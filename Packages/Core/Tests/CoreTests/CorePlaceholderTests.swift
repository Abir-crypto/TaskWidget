import Testing

@testable import Core

/// Placeholder suite so `swift test` has something to run. Delete it in T-02.
struct CorePlaceholderTests {
    @Test func coreModuleLinks() {
        #expect(CorePlaceholder.isLinked)
    }
}
