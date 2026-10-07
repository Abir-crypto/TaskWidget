import Core
import SwiftUI

/// Seven weekday toggles, starting on the region's first weekday (SPEC F-15).
struct WeekdayPicker: View {
    @Binding var selection: Weekdays
    let calendar: Calendar

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Weekday.ordered(firstWeekday: calendar.firstWeekday), id: \.self) { day in
                let isOn = selection.contains(day)
                Button {
                    if isOn { selection.remove(day.bit) } else { selection.insert(day.bit) }
                } label: {
                    Text(day.initial(in: calendar))
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(isOn ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill.tertiary), in: Circle())
                        .foregroundStyle(isOn ? .white : .primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(day.name(in: calendar))
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    Form {
        WeekdayPicker(selection: .constant([.monday, .wednesday, .friday]), calendar: .autoupdatingCurrent)
    }
}
