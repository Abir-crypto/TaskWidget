import Foundation
import Testing

@testable import Core

/// SPEC F-30 and §4.5: the missed style and how it's stored.
struct MissedStyleTests {
    @Test func choicesAreGentleAndStrictAndGentleIsTheDefault() {
        #expect(MissedStyle.allCases.map(\.rawValue) == ["gentle", "strict"])
        #expect(MissedStyle.default == .gentle)
        #expect(SettingsValue.defaults.missedStyle == .gentle)
    }

    @Test func choicesAreStoredByName() {
        for style in MissedStyle.allCases {
            #expect(MissedStyle(storedValue: style.rawValue) == style)
        }
    }

    @Test func anythingElseIsGentle() {
        for value in ["", "Strict", "STRICT", "harsh", "strict "] {
            #expect(MissedStyle(storedValue: value) == .gentle, "\(value)")
        }
    }

    @Test func decodingAnUnknownValueGivesGentle() throws {
        let decoded = try JSONDecoder().decode([MissedStyle].self, from: Data(#"["strict", "loud"]"#.utf8))
        #expect(decoded == [.strict, .gentle])
        let encoded = try JSONEncoder().encode([MissedStyle.strict])
        #expect(String(decoding: encoded, as: UTF8.self) == #"["strict"]"#)
    }
}
