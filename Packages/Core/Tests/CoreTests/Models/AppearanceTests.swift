import Foundation
import Testing

@testable import Core

/// SPEC F-28 and §4.5: the app's appearance and how it's stored.
struct AppearanceTests {
    @Test func choicesAreSystemDarkAndLightAndSystemIsTheDefault() {
        #expect(Appearance.allCases.map(\.rawValue) == ["system", "dark", "light"])
        #expect(Appearance.default == .system)
        #expect(SettingsValue.defaults.appearance == .system)
    }

    @Test func choicesAreStoredByName() {
        for appearance in Appearance.allCases {
            #expect(Appearance(storedValue: appearance.rawValue) == appearance)
        }
    }

    @Test func anythingElseIsSystem() {
        for value in ["", "System", "DARK", "auto", "light "] {
            #expect(Appearance(storedValue: value) == .system, "\(value)")
        }
    }

    @Test func decodingAnUnknownValueGivesSystem() throws {
        let decoded = try JSONDecoder().decode([Appearance].self, from: Data(#"["dark", "sepia"]"#.utf8))
        #expect(decoded == [.dark, .system])
        let encoded = try JSONEncoder().encode([Appearance.light])
        #expect(String(decoding: encoded, as: UTF8.self) == #"["light"]"#)
    }
}
