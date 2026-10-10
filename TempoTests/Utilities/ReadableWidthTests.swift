import CoreGraphics
import Testing

@testable import Tempo

/// SPEC F-25: content keeps to about 700 points, centered, and narrow screens keep their usual margins.
struct ReadableWidthTests {
    @Test func narrowScreensKeepTheirMargins() {
        #expect(ReadableWidth.margin(in: 390) == nil)
        #expect(ReadableWidth.margin(in: 700) == nil)
    }

    @Test func wideScreensCenterSevenHundredPoints() {
        #expect(ReadableWidth.margin(in: 744) == 22)
        #expect(ReadableWidth.margin(in: 1032) == 166)
        #expect(ReadableWidth.margin(in: 1366) == 333)
    }
}
