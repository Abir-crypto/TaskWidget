import Core
import SwiftUI
import UIKit

/// Settings › Theme (SPEC F-27): a swatch per preset, and Custom, which opens the system color picker. The current
/// choice is marked.
struct ThemePicker: View {
    let selection: ThemeColor
    let onSelect: (ThemeColor) -> Void

    private let columns = [GridItem(.adaptive(minimum: 44, maximum: 56), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(ThemePreset.allCases, id: \.self) { preset in
                presetSwatch(preset)
            }
            customSwatch
        }
        .padding(.vertical, 4)
    }

    private func presetSwatch(_ preset: ThemePreset) -> some View {
        let isSelected = selection == .preset(preset)
        return Button {
            onSelect(.preset(preset))
        } label: {
            Circle()
                .fill(preset.color)
                .frame(width: 32, height: 32)
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                .ringed(isSelected, color: preset.color)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(preset.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// The system color well; it shows the custom color once one is chosen.
    private var customSwatch: some View {
        let isSelected = if case .custom = selection { true } else { false }
        return ColorPicker(
            selection: Binding(
                get: { isSelected ? selection.color : ThemeColor.default.color },
                set: { onSelect(Self.themeColor(from: $0)) }),
            supportsOpacity: false
        ) {
            Text("Custom")
        }
        .labelsHidden()
        .ringed(isSelected, color: selection.color)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// A picked color in 8-bit sRGB, clamped, since the picker can return wide-gamut values.
    static func themeColor(from color: Color) -> ThemeColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        func byte(_ value: CGFloat) -> Int { Int((min(max(value, 0), 1) * 255).rounded()) }
        return .custom(red: byte(red), green: byte(green), blue: byte(blue))
    }
}

extension View {
    /// A 44-point target, with a ring around the chosen swatch.
    fileprivate func ringed(_ isSelected: Bool, color: Color) -> some View {
        padding(4)
            .overlay {
                if isSelected { Circle().stroke(color, lineWidth: 2) }
            }
            .frame(width: 44, height: 44)
            .contentShape(Circle())
    }
}

#Preview("A preset") {
    Form {
        Section("Theme") {
            ThemePicker(selection: .preset(.indigo)) { _ in }
        }
    }
    .tint(.indigo)
}

#Preview("Custom") {
    let custom = ThemeColor.custom(red: 30, green: 144, blue: 255)
    return Form {
        Section("Theme") {
            ThemePicker(selection: custom) { _ in }
        }
    }
    .tint(custom.color)
}
