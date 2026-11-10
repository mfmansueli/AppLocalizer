//
//  SegmentBadgeLayoutTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Testing
@testable import AppLocalizer

/// Where a badge sits on a segmented control, with text measured at 10 pt
/// a character so the numbers can be worked out by hand.
@Suite("SegmentBadgeLayout")
struct SegmentBadgeLayoutTests {
    private let layout = SegmentBadgeLayout(
        titles: ["Aa", "Bbbb", "Cc"],
        badgeWidths: [nil, 20, nil],
        measure: { CGFloat($0.count) * 10 }
    )

    @Test func onlyABadgedSegmentGetsRoomAfterItsTitle() {
        // 5 gap + 20 badge = 25 pt, three 10 pt spaces.
        #expect(layout.labels == ["Aa", "Bbbb" + String(repeating: SegmentBadgeLayout.space, count: 3), "Cc"])
    }

    @Test func theBadgeSitsRightAfterItsTitle() {
        // Labels 20 + 70 + 20 in 170 pt leave 20 pt of padding per segment.
        // Segment 1 starts at 40, its text at 50 and its title ends at 90.
        #expect(layout.badgeCenterX(at: 1, totalWidth: 170) == 105)
    }

    @Test func theBadgeStaysInsideTheSpaceKeptForIt() throws {
        let center = try #require(layout.badgeCenterX(at: 1, totalWidth: 170))
        #expect(center + 10 <= 50 + 70)
    }

    @Test func noBadgeNoPosition() {
        #expect(layout.badgeCenterX(at: 0, totalWidth: 170) == nil)
        #expect(layout.badgeCenterX(at: 9, totalWidth: 170) == nil)
    }
}
