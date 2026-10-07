import Core

/// One part of the day in the Day widget (SPEC F-19): its marks, at most 6 then "+N", and what's left.
struct DayColumn: Hashable {
    /// Marks shown per column before "+N".
    static let maximumMarks = 6

    let part: DayPart
    let isCurrent: Bool
    let marks: [DayMark]
    /// Marks that didn't fit ("+N").
    let extraCount: Int
    /// Tasks still Upcoming or Open.
    let leftCount: Int
    let hasTasks: Bool

    init(section: DaySection) {
        let all = section.items.map(DayMark.init)
        part = section.part ?? .morning
        isCurrent = section.phase == .current
        marks = Array(all.prefix(Self.maximumMarks))
        extraCount = max(all.count - Self.maximumMarks, 0)
        leftCount = section.leftCount
        hasTasks = !section.items.isEmpty
    }
}
