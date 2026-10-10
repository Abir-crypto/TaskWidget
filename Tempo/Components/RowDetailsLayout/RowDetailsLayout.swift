import SwiftUI

/// A row's main text and its details (a time, a status): the details sit on the right, or move under the main
/// text at accessibility text sizes so the title keeps its width (SPEC T-31).
struct RowDetailsLayout<Main: View, Details: View>: View {
    @ViewBuilder var main: Main
    @ViewBuilder var details: Details
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if typeSize.isAccessibilitySize {
            // Grow downward rather than truncate.
            VStack(alignment: .leading, spacing: 4) {
                main.fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: 2) { details }.fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(spacing: 0) {
                main
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) { details }
            }
        }
    }
}

#Preview {
    List {
        RowDetailsLayout {
            Text(verbatim: "Interview")
        } details: {
            Text(verbatim: "12:30").foregroundStyle(.secondary)
        }
        RowDetailsLayout {
            Text(verbatim: "Interview")
        } details: {
            Text(verbatim: "12:30").foregroundStyle(.secondary)
        }
        .dynamicTypeSize(.accessibility5)
    }
}
