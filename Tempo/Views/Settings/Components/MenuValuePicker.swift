import SwiftUI

/// A Settings row that picks one value from a menu, with the current value in the theme color. A plain menu-style
/// `Picker` draws its value in UIKit's own color and ignores the theme (SPEC F-27).
struct MenuValuePicker<Value: Hashable>: View {
    let title: LocalizedStringKey
    @Binding var selection: Value
    let options: [Value]
    let label: (Value) -> Text

    var body: some View {
        LabeledContent {
            Menu {
                Picker(title, selection: $selection) {
                    ForEach(options, id: \.self) { label($0).tag($0) }
                }
            } label: {
                HStack(spacing: 4) {
                    label(selection)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.semibold))
                        .accessibilityHidden(true)
                }
                .foregroundStyle(.tint)
            }
            .accessibilityLabel(Text(title))
            .accessibilityValue(label(selection))
        } label: {
            Text(title)
        }
    }
}

#Preview {
    Form {
        MenuValuePicker(title: "Before the task", selection: .constant(10), options: [5, 10, 15, 30]) {
            Text(verbatim: "\($0) min")
        }
    }
    .tint(.pink)
}
