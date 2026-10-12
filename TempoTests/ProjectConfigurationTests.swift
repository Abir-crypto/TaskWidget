import Foundation
import Testing

@testable import Tempo

/// Checks the T-01 setup from ios.md §2: identifiers, URL scheme, background refresh, App Group, widget extension.
struct ProjectConfigurationTests {
    private var info: [String: Any] { Bundle.main.infoDictionary ?? [:] }

    @Test func appBundleIdentifier() {
        #expect(Bundle.main.bundleIdentifier == "com.akumatech.tempo")
    }

    @Test func urlSchemeIsRegistered() {
        let types = info["CFBundleURLTypes"] as? [[String: Any]] ?? []
        let schemes = types.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
        #expect(schemes == ["tempo"])
    }

    @Test func backgroundRefreshIsConfigured() {
        let identifiers = info["BGTaskSchedulerPermittedIdentifiers"] as? [String] ?? []
        let modes = info["UIBackgroundModes"] as? [String] ?? []
        #expect(identifiers == ["com.akumatech.tempo.refresh"])
        #expect(modes == ["fetch"])
    }

    @Test func appGroupContainerIsAvailable() {
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.akumatech.tempo")
        #expect(url != nil)
    }

    /// The group the store and device state open must be one the app is entitled to; otherwise the store can't open
    /// ("client is not entitled") and the app shows "Can't open your tasks".
    @Test func storeUsesTheEntitledAppGroup() {
        #expect(FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: StoreFactory.appGroup) != nil)
    }

    /// The app and its extension both run on iOS 18.0 and later (D-104).
    @Test func deploymentTargetIsiOS18() {
        let widgets = Bundle.main.builtInPlugInsURL.flatMap { Bundle(url: $0.appending(path: "TempoWidgets.appex")) }
        #expect(info["MinimumOSVersion"] as? String == "18.0")
        #expect(widgets?.infoDictionary?["MinimumOSVersion"] as? String == "18.0")
    }

    @Test func widgetExtensionIsEmbedded() {
        let url = Bundle.main.builtInPlugInsURL?.appending(path: "TempoWidgets.appex")
        let widgets = url.flatMap { Bundle(url: $0) }
        #expect(widgets?.bundleIdentifier == "com.akumatech.tempo.widgets")
    }
}
