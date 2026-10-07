import SwiftUI
import UIKit

/// A time-of-day picker with a minute step, bound to a minute of the day (ios.md §12).
/// SwiftUI's `DatePicker` has no minute interval, so this wraps `UIDatePicker`.
struct MinuteIntervalPicker: UIViewRepresentable {
    @Binding var minute: Int
    /// 15 in Settings, 5 in the editor.
    var interval: Int
    /// The earliest and latest minutes that can be picked.
    var range: ClosedRange<Int>?
    var accessibilityLabel: String

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .compact
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        picker.calendar = calendar
        picker.timeZone = .gmt
        picker.setContentHuggingPriority(.required, for: .horizontal)
        picker.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        return picker
    }

    func updateUIView(_ picker: UIDatePicker, context: Context) {
        context.coordinator.parent = self
        picker.minuteInterval = interval
        picker.minimumDate = range.map { TimeOfDayFormatter.date(minute: $0.lowerBound) }
        picker.maximumDate = range.map { TimeOfDayFormatter.date(minute: $0.upperBound) }
        let wanted = TimeOfDayFormatter.date(minute: minute)
        if picker.date != wanted {
            picker.date = wanted
        }
        picker.accessibilityLabel = accessibilityLabel
    }

    @MainActor
    final class Coordinator: NSObject {
        var parent: MinuteIntervalPicker

        init(parent: MinuteIntervalPicker) {
            self.parent = parent
        }

        @objc func changed(_ picker: UIDatePicker) {
            let step = max(parent.interval, 1)
            var minute = TimeOfDayFormatter.minute(of: picker.date) / step * step
            if let range = parent.range {
                minute = min(max(minute, range.lowerBound), range.upperBound)
            }
            if minute != parent.minute {
                parent.minute = minute
            }
        }
    }
}

#Preview {
    Form {
        LabeledContent {
            MinuteIntervalPicker(
                minute: .constant(360), interval: 15, range: 0...690, accessibilityLabel: "Morning starts")
        } label: {
            Text(verbatim: "Morning")
        }
    }
}
