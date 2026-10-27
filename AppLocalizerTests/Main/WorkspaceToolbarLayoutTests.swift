//
//  WorkspaceToolbarLayoutTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Testing
@testable import AppLocalizer

/// The toolbar title gives way before Review & Push does.
@Suite("WorkspaceToolbarLayout")
struct WorkspaceToolbarLayoutTests {
    private func layout(detail: CGFloat, indicator: CGFloat = 0) -> WorkspaceToolbarLayout {
        WorkspaceToolbarLayout(detailWidth: detail, pickerWidth: 430, indicatorWidth: indicator)
    }

    @Test func unmeasuredKeepsTheFullTitle() {
        #expect(WorkspaceToolbarLayout().spareWidth == nil)
        #expect(!WorkspaceToolbarLayout().isTitleCompact)
    }

    @Test func theTitleHasWhatTheOtherItemsLeave() {
        #expect(layout(detail: 940).spareWidth == 940 - 430 - WorkspaceToolbarLayout.fixedWidth)
    }

    @Test func theAssistantIndicatorMakesTheTitleCompactAtTheDefaultWidth() {
        #expect(!layout(detail: 940).isTitleCompact)
        #expect(layout(detail: 940, indicator: 110).isTitleCompact)
        #expect(!layout(detail: 1200, indicator: 110).isTitleCompact)
    }
}
