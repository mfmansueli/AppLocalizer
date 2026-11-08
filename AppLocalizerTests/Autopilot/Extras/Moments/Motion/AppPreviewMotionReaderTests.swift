//
//  AppPreviewMotionReaderTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Comparing two frames: the status bar's clock and the Home indicator
/// don't count, and neither does video noise.
@Suite("App Preview moments · comparing frames")
struct AppPreviewMotionReaderTests {
    private static let width = 10
    private static let height = 100
    /// Rows 8 to 95 are compared.
    private static let comparedPixels = 880.0

    private static var blank: [UInt8] {
        [UInt8](repeating: 100, count: width * height)
    }

    private static func changed(rows: Range<Int>, to value: UInt8 = 200) -> Double {
        var after = blank
        for row in rows {
            for column in 0..<width { after[row * width + column] = value }
        }
        return AppPreviewMotionReader.changedShare(blank, after, width: width, height: height)
    }

    @Test func aChangedRowCounts() {
        #expect(Self.changed(rows: 50..<51) == 10 / Self.comparedPixels)
    }

    @Test func theStatusBarIsLeftOut() {
        #expect(Self.changed(rows: 0..<8) == 0)
    }

    @Test func theHomeIndicatorIsLeftOut() {
        #expect(Self.changed(rows: 96..<100) == 0)
    }

    @Test func videoNoiseIsntAChange() {
        #expect(Self.changed(rows: 10..<90, to: 110) == 0)
        #expect(Self.changed(rows: 10..<90, to: 111) > 0)
    }

    @Test func framesThatDontMatchCompareAsTheSame() {
        #expect(AppPreviewMotionReader.changedShare([1, 2], [3], width: 2, height: 1) == 0)
        #expect(AppPreviewMotionReader.changedShare([], [], width: 0, height: 0) == 0)
    }
}
