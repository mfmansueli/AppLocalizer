//
//  AutopilotWithoutScreenshotsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// A run that makes no screenshots says so everywhere: the sheet's header
/// says what it makes, Design's log what each direction brought, Design
/// and Choose what each direction is, the directions show only their
/// header and search (bigger, the header on a line of its own in a narrow
/// card), and the header is checked against the live screenshots that stay.
@MainActor
@Suite("Autopilot · a run without screenshots")
struct AutopilotWithoutScreenshotsTests {
    private static var headerAndSearch: AutopilotPlan { StudioDebugWebArtwork.artworkOnly(.choose).plan }

    // MARK: - What the run makes

    @Test func theSheetSaysWhatTheRunMakes() {
        var plan = Self.headerAndSearch
        plan.alsoMakes.setMotion(.still)
        #expect(plan.scopeTitle == "Header and search artwork · \(plan.localeCodes.count) languages")

        plan.alsoMakes.artworkSize = .wide
        #expect(plan.scopeTitle.hasPrefix("One 16:9 header and search image · "))

        var preview = StudioDebugExtras.run(.choose, languages: .primary).plan
        AutopilotRunPreset.appPreview.apply(to: &preview, devices: [.iPhone, .iPad], canReuse: true)
        #expect(preview.scopeTitle == "An App Preview in English (U.S.)", "Its title has its language")

        let screenshots = StudioDebugExtras.run(.choose).plan
        #expect(screenshots.scopeTitle.contains("screens"))
    }

    @Test func aDirectionIsWhatTheRunMakes() {
        var plan = Self.headerAndSearch
        #expect(plan.directionTitle == "header and search")
        plan.alsoMakes.artworkSize = .wide
        #expect(plan.directionTitle == "16:9 image")
        plan.alsoMakes.makesArtwork = false
        #expect(plan.directionTitle == "App Preview look")
        #expect(StudioDebugExtras.run(.choose).plan.directionTitle == "template")
    }

    @Test func designAndChooseSayWhatEachDirectionIs() {
        #expect(AutopilotDesignStageView.eachDirection(Self.headerAndSearch)
            == "each direction is its own header and search images, and the live screenshots stay as they are")
        #expect(AutopilotDesignStageView.eachDirection(StudioDebugExtras.run(.choose).plan) == "each direction is an AppLocalizer template")
    }

    // MARK: - Fitting the header and search

    /// A run from before header concepts making `plan`: its directions
    /// bring the header and search.
    static func run(_ plan: AutopilotPlan) -> AutopilotRun {
        var run = StudioDebugExtras.run(.choose)
        run.plan = plan
        run.proposesConcepts = nil
        return run
    }

    /// A card as narrow as Alba's (154 pt inside): side by side they'd be
    /// 38 pt tall.
    @Test func inANarrowCardTheHeaderTakesALineOfItsOwn() {
        let fit = AutopilotDesignStageView.extrasFit(Self.run(Self.headerAndSearch), cardWidth: 154)
        #expect(fit.stacks)
        #expect(fit.height == 66, "154 ÷ (3840 ÷ 1646)")
        #expect(fit.secondHeight == 96, "The search image, at most 96")

        let wide = AutopilotDesignStageView.extrasFit(Self.run(Self.headerAndSearch), cardWidth: 340)
        #expect(!wide.stacks, "Side by side they're big enough")
        #expect(wide.height == 86)
    }

    @Test func underTheScreenshotsTheyStaySmallAndOnOneLine() {
        let run = StudioDebugExtras.run(.choose)
        let plan = run.plan
        let fit = AutopilotDesignStageView.extrasFit(run, cardWidth: 154)
        #expect(!fit.stacks)
        #expect(fit.height == AutopilotDirectionExtras.fittingHeight(in: 154, kinds: plan.artworkKinds, hasPreview: true))
        #expect(AutopilotChooseStageView.extrasFit(run, in: 900) == AutopilotDirectionExtras.Fit(height: 64))
    }

    @Test func chooseGivesThemTheRoomBesideTheText() {
        #expect(AutopilotChooseStageView.extrasFit(Self.run(Self.headerAndSearch), in: 900) == AutopilotDirectionExtras.Fit(height: 120))
        let narrow = AutopilotChooseStageView.extrasFit(Self.run(Self.headerAndSearch), in: 700)
        #expect(!narrow.stacks, "A row stays one line")
        #expect(narrow.height == 87) // (700 − 320 − 36 − 8) ÷ (21:9 + 3:2)
    }

    @Test(arguments: [CGFloat(120), 154, 201, 268, 340])
    func stackedTheyStillFitTheCard(width: CGFloat) {
        let fit = AutopilotDirectionExtras.fit(in: width, kinds: [.header, .search], hasPreview: false, maximum: 96, stacking: true)
        let lines = fit.secondHeight.map { second in
            [fit.height * AutopilotDirectionExtras.ratio(.header), second * AutopilotDirectionExtras.ratio(.search)]
        } ?? [fit.height * AutopilotDirectionExtras.ratio(.header) + fit.height * AutopilotDirectionExtras.ratio(.search) + Spacing.small]
        #expect(lines.allSatisfy { $0 <= width + 1 }, "\(fit) is \(lines) wide in \(width)")
    }

    @Test func oneImageNeverStacks() {
        let fit = AutopilotDirectionExtras.fit(in: 154, kinds: [.wide], hasPreview: false, maximum: 96, stacking: true)
        #expect(!fit.stacks)
    }

    // MARK: - The header's look

    @Test func theHeaderContinuesTheLiveScreenshots() throws {
        let live = ScreenshotTemplate.starter(.panorama, id: "live", title: "Live", slotCount: 5)
        let artworkOnly = StudioDebugWebArtwork.artworkOnly(.choose)
        #expect(AutopilotArtworkMaker.screenshotLook(of: artworkOnly, live: live) == live)

        let withScreenshots = StudioDebugExtras.run(.localize)
        let chosen = try #require(withScreenshots.chosenDirection)
        #expect(AutopilotArtworkMaker.screenshotLook(of: withScreenshots, live: live) == chosen.template, "The new set's")
    }
}
#endif
