import Testing

@testable import Core

/// SPEC F-27 and §4.5: the theme color and how it's stored.
struct ThemeColorTests {
    @Test func presetsAreStoredByName() {
        for preset in ThemePreset.allCases {
            let color = ThemeColor.preset(preset)
            #expect(color.storedValue == preset.rawValue)
            #expect(ThemeColor(storedValue: preset.rawValue) == color)
        }
    }

    @Test func thereAreEightPresetsAndBlueIsTheDefault() {
        #expect(
            ThemePreset.allCases.map(\.rawValue) == [
                "blue", "indigo", "purple", "pink", "red", "orange", "green", "teal",
            ])
        #expect(ThemeColor.default == .preset(.blue))
        #expect(SettingsValue.defaults.tintColor == .preset(.blue))
    }

    @Test func customColorsAreStoredAsHex() {
        let color = ThemeColor.custom(red: 30, green: 144, blue: 255)
        #expect(color.storedValue == "#1E90FF")
        #expect(ThemeColor(storedValue: "#1E90FF") == color)
        #expect(ThemeColor(storedValue: "#1e90ff") == color)
        #expect(ThemeColor(storedValue: "#000000") == .custom(red: 0, green: 0, blue: 0))
    }

    @Test func customComponentsAreClampedTo0Through255() {
        #expect(ThemeColor.custom(red: -4, green: 300, blue: 128).storedValue == "#00FF80")
    }

    @Test func anythingElseIsBlue() {
        for value in ["", "Blue", "yellow", "#12345", "#1234567", "#GGHHII", "1E90FF", "# 1E90F", "#1E90FF "] {
            #expect(ThemeColor(storedValue: value) == .preset(.blue), "\(value)")
        }
    }
}
