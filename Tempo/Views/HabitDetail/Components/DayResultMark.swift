import Core
import SwiftUI

/// A day's result as an icon with a matching color, so it never relies on color alone.
struct DayResultMark: View {
    let result: DayResult
    @Environment(\.missedStyle) private var missedStyle

    var body: some View {
        Image(systemName: result.systemImage(missedStyle))
            .foregroundStyle(color)
            .accessibilityLabel(result.label(missedStyle))
    }

    private var color: Color {
        switch result {
        case .done: .green
        case .short: .orange
        case .missed: missedStyle.color
        case .upcoming: .secondary
        case .notScheduled: Color(uiColor: .tertiaryLabel)
        }
    }
}

#Preview {
    HStack {
        ForEach([DayResult.done, .short, .missed, .upcoming, .notScheduled], id: \.self) { DayResultMark(result: $0) }
        DayResultMark(result: .missed).environment(\.missedStyle, .strict)
    }
    .font(.title)
}
