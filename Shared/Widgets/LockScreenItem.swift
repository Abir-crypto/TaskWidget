import Foundation

/// The task a Lock Screen widget shows (SPEC F-22), with its lines for the rectangular and inline sizes.
struct LockScreenItem: Hashable {
    let title: String
    /// The rectangular size's first line without the self-updating part: "12:30", "Noon · until 17:00",
    /// "Evening · 10 of 30 min", "Evening · from 17:00" or "Anytime".
    let topLine: String
    /// A fixed-time task's moment, for the self-updating "in 45 min" after `topLine`.
    let countdownTo: Date?
    /// The inline size's line: "Next: Interview at 12:30", "Noon: Call the bank" or "Anytime: Renew passport".
    let inline: String
    /// "Hide task names on the Lock Screen" is on, so the title is hidden while the device is locked (SPEC F-16).
    let hidesTitle: Bool
    let url: URL

    init(_ item: NextTaskItem, hidesTitle: Bool) {
        title = item.title
        self.hidesTitle = hidesTitle
        url = item.url
        switch (item.when, item.progress) {
        case (_, let progress?):
            // Duration habits show their progress after their time, part or "Anytime" (D-092).
            topLine = "\(item.when.place) · \(progress)"
            countdownTo = nil
        case (.next(_, let date), nil):
            topLine = item.when.place
            countdownTo = date
        case (.currentPart, nil), (.laterPart, nil):
            topLine = "\(item.when.place) · \(item.when.timeRange)"
            countdownTo = nil
        case (.anytime, nil):
            topLine = item.when.place
            countdownTo = nil
        }
        if case .next = item.when {
            inline = String(localized: "Next: \(item.title) at \(item.when.place)")
        } else {
            inline = String(localized: "\(item.when.place): \(item.title)")
        }
    }
}
