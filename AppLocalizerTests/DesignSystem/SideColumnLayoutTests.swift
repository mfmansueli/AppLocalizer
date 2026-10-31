//
//  SideColumnLayoutTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Testing
@testable import AppLocalizer

@Suite("SideColumnLayout")
struct SideColumnLayoutTests {
    /// Age Rating's: a 250 pt preview, 20 pt apart, beside at least 420 pt.
    private let layout = SideColumnLayout(sideWidth: 250, minimumMainWidth: 420, spacing: 20)

    @Test func theColumnGoesBesideWhenTheContentKeepsItsMinimum() {
        #expect(layout.placesBeside(in: 690, mainMinimumWidth: 300))
        #expect(layout.placesBeside(in: 1200, mainMinimumWidth: 300))
    }

    @Test func narrowerThanThatItGoesAbove() {
        #expect(!layout.placesBeside(in: 689, mainMinimumWidth: 300))
        #expect(!layout.placesBeside(in: 0, mainMinimumWidth: 300))
    }

    /// Content that can't be as narrow as the minimum (a long translation
    /// on a button) keeps the column above until it fits beside.
    @Test func contentWiderThanTheMinimumNeedsMoreRoom() {
        #expect(!layout.placesBeside(in: 700, mainMinimumWidth: 480))
        #expect(layout.placesBeside(in: 750, mainMinimumWidth: 480))
    }

    @Test func anIdealSizePutsItBeside() {
        #expect(layout.placesBeside(in: nil, mainMinimumWidth: 480))
    }
}
