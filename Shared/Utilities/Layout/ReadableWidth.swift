import CoreGraphics

/// The readable width that content keeps to on wide screens (SPEC F-25, ios.md §12).
enum ReadableWidth {
    static let maxWidth: CGFloat = 700

    /// The side margin that centers readable-width content in a container this wide, or `nil` when the container
    /// is already narrow enough and the default margins apply.
    static func margin(in containerWidth: CGFloat) -> CGFloat? {
        let extra = (containerWidth - maxWidth) / 2
        return extra > 0 ? extra : nil
    }
}
