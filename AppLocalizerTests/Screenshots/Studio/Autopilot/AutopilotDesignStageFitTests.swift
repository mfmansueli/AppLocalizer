//
//  AutopilotDesignStageFitTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// Design's three cards share the sheet's width: the screenshots shrink to
/// fit (Apple Vision Pro and Apple Watch on their own line when that's
/// bigger), and the header, search and App Preview poster row too.
@MainActor
@Suite("Autopilot Design stage · fitting the cards")
struct AutopilotDesignStageFitTests {
    /// Alba's sheet at its 960-pt minimum: 739 pt beside the stage list,
    /// 699 inside the page's padding, so 225 per card.
    @Test func theCardsShareWhatTheSheetHasLeft() {
        #expect(AutopilotDesignCardsLayout.cardWidth(in: 699, count: 3) == 225)
        #expect(AutopilotDesignCardsLayout.cardWidth(in: 699, count: 0) == 699)
        #expect(AutopilotDesignCardsLayout.cardWidth(in: 10, count: 3) == 0)
    }

    @Test func theSetShrinksToFitAndNeverGrowsPastItsSize() {
        #expect(AutopilotDirectionThumbnails.fittingThumbnail(in: 200, screens: 5, hasVision: false, hasWatch: false, maximum: 44) == 36)
        #expect(AutopilotDirectionThumbnails.fittingThumbnail(in: 900, screens: 5, hasVision: false, hasWatch: false, maximum: 44) == 44)
        #expect(AutopilotDirectionThumbnails.fittingThumbnail(in: 0, screens: 5, hasVision: false, hasWatch: false, maximum: 44) == 12)
    }

    @Test(arguments: [CGFloat(180), 220, 268, 320])
    func theThumbnailsFitTheCard(width: CGFloat) {
        let fit = AutopilotDirectionThumbnails.fit(in: width, screens: 5, hasVision: true, hasWatch: true, maximum: 44)
        let set = AutopilotDirectionThumbnails.oneRowWidth(thumbnail: fit.thumbnail, screens: 5, hasVision: false, hasWatch: false)
        let devices = fit.thumbnail * 2.8 + Spacing.xSmall
        let used = fit.stacks ? max(set, devices) : AutopilotDirectionThumbnails.oneRowWidth(
            thumbnail: fit.thumbnail, screens: 5, hasVision: true, hasWatch: true
        )
        #expect(used <= width, "\(fit) is \(used) wide in \(width)")
    }

    @Test func appleVisionProAndAppleWatchGoUnderWhenThatsBigger() {
        let narrow = AutopilotDirectionThumbnails.fit(in: 200, screens: 5, hasVision: true, hasWatch: true, maximum: 44)
        #expect(narrow.stacks)
        #expect(narrow.thumbnail == 36)

        let wide = AutopilotDirectionThumbnails.fit(in: 600, screens: 5, hasVision: true, hasWatch: true, maximum: 44)
        #expect(!wide.stacks, "At full size they stay beside the set")
        #expect(wide.thumbnail == 44)

        let setOnly = AutopilotDirectionThumbnails.fit(in: 200, screens: 5, hasVision: false, hasWatch: false, maximum: 44)
        #expect(!setOnly.stacks)
    }

    @Test(arguments: [CGFloat(160), 220, 268])
    func theExtrasRowFitsTheCard(width: CGFloat) {
        let kinds: [AutopilotArtworkKind] = [.header, .search]
        let height = AutopilotDirectionExtras.fittingHeight(in: width, kinds: kinds, hasPreview: true)
        let images = kinds.reduce(0) { $0 + (height * AutopilotDirectionExtras.ratio($1)).rounded(.down) }
        let used = images + (height * AutopilotDirectionExtras.posterRatio).rounded(.down) + Spacing.small * 2
        #expect(used <= width, "\(height) high is \(used) wide in \(width)")
        #expect(height <= 64)
    }

    @Test func theExtrasRowKeepsItsHeightWhenThereIsRoom() {
        #expect(AutopilotDirectionExtras.fittingHeight(in: 900, kinds: [.header, .search], hasPreview: true) == 64)
        #expect(AutopilotDirectionExtras.fittingHeight(in: 900, kinds: [], hasPreview: false) == 64)
        #expect(AutopilotDirectionExtras.fittingHeight(in: 0, kinds: [.wide], hasPreview: false) == 16)
    }

    @Test func onlyAnArrivedDirectionIsACardYouCanOpen() {
        let direction = StudioDebugRuns.run(.choose).directions[0]
        #expect(AutopilotDirectionCard.arrived(direction).isArrived)
        #expect(!AutopilotDirectionCard.designing(since: nil).isArrived)
        #expect(!AutopilotDirectionCard.upNext.isArrived)
        #expect(!AutopilotDirectionCard.waiting.isArrived)
    }
}
