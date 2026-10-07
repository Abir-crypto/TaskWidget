import Foundation
import Testing

/// Checks the T-01 setup from ios.md §2: identifiers, URL scheme, background refresh, App Group, widget extension.
struct ProjectConfigurationTests {
    private var info: [String: Any] { Bundle.main.infoDictionary ?? [:] }

    @Test func appBundleIdentifier() {
        #expect(Bundle.main.bundleIdentifier == "com.applab.tempo")
    }

    @Test func urlSchemeIsRegistered() {
        let types = info["CFBundleURLTypes"] as? [[String: Any]] ?? []
        let schemes = types.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
        #expect(schemes == ["tempo"])
    }

    @Test func backgroundRefreshIsConfigured() {
        let identifiers = info["BGTaskSchedulerPermittedIdentifiers"] as? [String] ?? []
        let modes = info["UIBackgroundModes"] as? [String] ?? []
        #expect(identifiers == ["com.applab.tempo.refresh"])
        #expect(modes == ["fetch"])
    }

    @Test func appGroupContainerIsAvailable() {
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.applab.tempo")
        #expect(url != nil)
    }

    @Test func widgetExtensionIsEmbedded() {
        let url = Bundle.main.builtInPlugInsURL?.appending(path: "TempoWidgets.appex")
        let widgets = url.flatMap { Bundle(url: $0) }
        #expect(widgets?.bundleIdentifier == "com.applab.tempo.widgets")
    }
}
