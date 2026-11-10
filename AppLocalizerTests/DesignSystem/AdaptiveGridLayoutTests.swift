//
//  AdaptiveGridLayoutTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Testing
@testable import AppLocalizer

/// The Overview's cards: as many columns of at least 270 points as fit,
/// sharing the width, and one column however narrow.
@Suite("Adaptive grid layout")
struct AdaptiveGridLayoutTests {
    @Test func asManyColumnsAsFitAtTheMinimum() {
        #expect(AdaptiveGridLayout.columnCount(width: 1050, minimumWidth: 270, spacing: 14) == 3)
        #expect(AdaptiveGridLayout.columnCount(width: 838, minimumWidth: 270, spacing: 14) == 3)
        #expect(AdaptiveGridLayout.columnCount(width: 837, minimumWidth: 270, spacing: 14) == 2)
        #expect(AdaptiveGridLayout.columnCount(width: 200, minimumWidth: 270, spacing: 14) == 1)
        #expect(AdaptiveGridLayout.columnCount(width: 0, minimumWidth: 270, spacing: 14) == 1)
    }

    @Test func columnsShareTheWidth() {
        #expect(AdaptiveGridLayout.columnWidth(width: 838, columns: 3, spacing: 14) == 270)
        #expect(AdaptiveGridLayout.columnWidth(width: 200, columns: 1, spacing: 14) == 200)
        #expect(AdaptiveGridLayout.columnWidth(width: 10, columns: 3, spacing: 14) == 0)
    }
}
