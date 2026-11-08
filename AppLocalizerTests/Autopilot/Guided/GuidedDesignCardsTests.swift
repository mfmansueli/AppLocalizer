//
//  GuidedDesignCardsTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// Making it's look cards share the sheet's width: a look's thumbnails
/// shrink to fit its card rather than widen the page.
@MainActor
@Suite("Guided making · look cards")
struct GuidedDesignCardsTests {
    /// The guided sheet's page, 960 pt less its margins.
    private static let page: CGFloat = 896

    @Test func aShortSetKeepsTheLargestThumbnails() {
        let fit = GuidedDesignCards.thumbnails(in: Self.page, count: 3, screens: 5, hasVision: false, hasWatch: false)
        #expect(fit.thumbnail == GuidedDesignCards.largestThumbnail)
        #expect(!fit.stacks)
    }

    /// Bruma's nine screens, three looks: at 40 pt the cards came to about
    /// 1,190 pt and the page slid off the sheet's left edge.
    @Test(arguments: [9, 10, 12])
    func aLongSetFitsItsCard(screens: Int) {
        let fit = GuidedDesignCards.thumbnails(in: Self.page, count: 3, screens: screens, hasVision: false, hasWatch: false)
        let card = AutopilotDesignCardsLayout.cardWidth(in: Self.page, count: 3) - GuidedDesignCards.cardPadding * 2
        let row = AutopilotDirectionThumbnails.oneRowWidth(thumbnail: fit.thumbnail, screens: screens, hasVision: false, hasWatch: false)
        #expect(fit.thumbnail < GuidedDesignCards.largestThumbnail)
        #expect(row <= card)
    }

    @Test func otherDevicesFitTooOnALineOfTheirOwn() {
        let fit = GuidedDesignCards.thumbnails(in: Self.page, count: 3, screens: 9, hasVision: true, hasWatch: true)
        let card = AutopilotDesignCardsLayout.cardWidth(in: Self.page, count: 3) - GuidedDesignCards.cardPadding * 2
        let set = AutopilotDirectionThumbnails.oneRowWidth(thumbnail: fit.thumbnail, screens: 9, hasVision: false, hasWatch: false)
        #expect(set <= card)
        if !fit.stacks {
            #expect(AutopilotDirectionThumbnails.oneRowWidth(thumbnail: fit.thumbnail, screens: 9, hasVision: true, hasWatch: true) <= card)
        }
    }

    /// Before the row is measured its width is 0: the thumbnails start
    /// small, never wide enough to push the page.
    @Test func anUnmeasuredRowStartsSmall() {
        let fit = GuidedDesignCards.thumbnails(in: 0, count: 3, screens: 9, hasVision: false, hasWatch: false)
        #expect(fit.thumbnail <= 12)
    }
}
