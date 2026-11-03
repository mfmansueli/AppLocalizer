//
//  ArtworkExtrasToolsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The assistant's side of the header and search artwork: the roles the
/// brief gives it, the texts Localize asks it to write and how they're
/// saved, and the Product Page Optimization variant it's asked for and
/// sends back.
@MainActor
@Suite("Artwork extras tools")
struct ArtworkExtrasToolsTests {
    // MARK: - The brief

    @Test func theBriefGivesEachPlacementItsRole() async throws {
        let brief = try await MCPAutopilotFixtures(StudioDebugExtras.run(.design)).call(GetDesignBriefTool(), ["run": "run-debug"]).result
        let extras = try #require(brief["extras"])
        let search = try #require(extras["roles"]?["search"]?.stringValue)
        #expect(search.contains("real interface doing the core task"))
        #expect(search.contains("one focal point, centered, readable at small size"))
        let header = try #require(extras["roles"]?["header"]?.stringValue)
        #expect(header.contains("Brand first: the app name and one short line"))
        #expect(header.contains("centered, with no phone"))
        #expect(header.contains("continuous with the app icon and the first screenshot"))
        #expect(extras["captures"]?.stringValue?.contains("real picked captures") == true)
        #expect(extras["rules"]?.stringValue?.contains("4+ age rating") == true)
        #expect(extras["video"]?.stringValue?.contains("always muted, so its first second shows the core action") == true)
        #expect(extras["video"]?.stringValue?.contains("loops without a visible jump") == true)
        #expect(extras["canvases"]?.arrayValue?.compactMap { $0["text"]?.stringValue } == ["header", "search"])
        #expect(extras["bothCrops"] == nil)

        let wide = try await MCPAutopilotFixtures(StudioDebugExtras.run(.design, size: .wide)).call(GetDesignBriefTool(), ["run": "run-debug"]).result
        #expect(wide["extras"]?["bothCrops"]?.stringValue?.contains("center safe area") == true)
        #expect(wide["extras"]?["canvases"]?.arrayValue?.first?["text"] == "search")
    }

    /// Board 32: still or a loop, what the search artwork shows, and the
    /// person's expected result, as rows the design source reads.
    @Test func theBriefSaysStillOrMotionAndWhatTheArtworkShows() async throws {
        let still = try await MCPAutopilotFixtures(StudioDebugExtras.run(.design)).call(GetDesignBriefTool(), ["run": "run-debug"]).result
        let plain = try #require(still["extras"])
        #expect(plain["art_motion"] == "still")
        #expect(plain["art_show"] == "phone")
        #expect(plain["art_direction"] == nil)
        let stillRows = plain["art_brief"]?.arrayValue?.compactMap { $0["rule"]?.stringValue }
        #expect(stillRows == ["Header · 21:9", "Search results · 3:2", "One look for both", "Still image", "Words"])

        let run = StudioDebugArtMotion.artworkOnly(.design, shows: .scene, withDirection: true)
        let moving = try await MCPAutopilotFixtures(run).call(GetDesignBriefTool(), ["run": "run-debug"]).result
        let extras = try #require(moving["extras"])
        #expect(extras["art_motion"] == "loop")
        #expect(extras["art_show"] == "scene")
        #expect(extras["captures"]?.stringValue?.hasPrefix("No app screens and no device") == true)
        #expect(extras["video"]?.stringValue?.contains("20-second silent loop (.mov, 30 fps)") == true)
        #expect(extras["video"]?.stringValue?.contains("its last frame matches the first") == true)
        let direction = try #require(extras["art_direction"])
        #expect(direction["text"]?.stringValue == StudioDebugArtMotion.direction.trimmedText)
        #expect(direction["references"]?.arrayValue?.compactMap { $0["kind"]?.stringValue } == ["video", "video"])
        let rows = try #require(extras["art_brief"]?.arrayValue)
        #expect(rows.compactMap { $0["rule"]?.stringValue } == [
            "Header · 21:9", "Search results · 3:2", "One look for both", "Motion · 20-second loop", "Poster, loop and sound",
            "Your direction", "Words",
        ])
        let search = rows.first { $0["rule"] == "Search results · 3:2" }?["says"]?.stringValue
        #expect(search?.contains("a scene in the brand’s style, with no app screens and no device") == true)
        let motion = rows.first { $0["rule"] == "Motion · 20-second loop" }?["says"]?.stringValue
        #expect(motion?.contains("float") == false, "A scene has no phone to float")
    }

    @Test(arguments: [(AutopilotArtworkShow.phone, ", a slight float of the phone"), (.ui, ", a slight float of the screen")])
    func aLoopFloatsWhatTheArtworkShows(shows: AutopilotArtworkShow, float: String) {
        var extras = AutopilotExtras(makesArtwork: true)
        extras.setMotion(.loop)
        extras.artworkShows = shows
        let motion = AutopilotArtworkBrief(extras).rows.first { $0.title == "Motion · 20-second loop" }
        #expect(motion?.text.contains(float) == true)
    }

    // MARK: - Texts

    private var localizing: AutopilotRun {
        var run = StudioDebugExtras.run(.localize)
        run.plan.localeCodes = ["en-US", "de-DE"]
        run.overflows = []
        run.shortenings = []
        run.artworkTextNeeds = [AutopilotArtworkTextNeed(locale: "de-DE", role: .search, problem: .missing)]
        return run
    }

    @Test func nextStepAsksForTheTextsOnceCaptionsFit() async throws {
        let outcome = try await MCPAutopilotFixtures(localizing).call(NextStepTool(), ["run": "run-debug"])
        #expect(outcome.result["action"] == "write_artwork_texts")
        #expect(outcome.result["texts"]?.arrayValue?.first?["placement"] == "search")
    }

    @Test func placementTextsAreSavedRightAway() async throws {
        let fixtures = MCPAutopilotFixtures(localizing)
        let outcome = try await fixtures.call(ProposeCaptionsTool(), [
            "run": "run-debug", "reason": "Search headlines.",
            "items": [
                ["locale": "de", "placement": "search", "headline": " Tagebuch in Sekunden "],
                ["locale": "en-US", "placement": "header", "headline": "Calm mornings"],
            ],
        ])
        #expect(outcome.result["status"] == "saved")
        #expect(outcome.result["saved"] == 2)
        #expect(outcome.logLines == [
            .init(target: "Lumen Journal · de-DE · Search results", outcome: .proposed),
            .init(target: "Lumen Journal · en-US · Header", outcome: .proposed),
        ])
        let document = try await fixtures.services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS)
        #expect(document.artworkTexts?.headline(.search, locale: "de-DE") == "Tagebuch in Sekunden")
        #expect(document.artworkTexts?.text(.header, locale: "en-US")?.provenance == .assistant(client: "Claude Code", date: AutopilotTestFixtures.now))
    }

    @Test func everyLanguageNeedsASearchHeadline() async throws {
        let outcome = try await MCPAutopilotFixtures(localizing).call(ProposeCaptionsTool(), [
            "run": "run-debug", "reason": "x", "items": [["locale": "de-DE", "placement": "search", "headline": "  "]],
        ])
        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["reason"] == "Every language needs a search headline.")
    }

    // MARK: - The Product Page Optimization variant

    /// Ready in English and German, with the header and search artwork saved.
    private func ready() -> MCPAutopilotFixtures {
        var run = StudioDebugExtras.run(.ready)
        run.plan.localeCodes = ["en-US", "de-DE"]
        let fixtures = MCPAutopilotFixtures(run)
        let extras = StudioDebugExtras.extras(for: run)
        fixtures.services.documentChange = { $0.extras = extras }
        return fixtures
    }

    @Test func aFinishedRunIsDoneUntilAVariantIsAskedFor() async throws {
        let fixtures = ready()
        #expect(try await fixtures.call(NextStepTool(), ["run": "run-debug"]).result["action"] == "done")

        #expect(fixtures.center.requestVariant(appID: MCPAutopilotFixtures.appID, role: .header, kind: .header))
        let step = try await fixtures.call(NextStepTool(), ["run": "run-debug"]).result
        #expect(step["action"] == "design_variant")
        #expect(step["placement"] == "header")
        #expect(step["pixelSize"] == "3840 × 1646")
        #expect(step["control"]?["name"] == "Interface")
        #expect(step["variant"]?["name"] == "Outcome")
        #expect(step["how"]?.stringValue?.contains("ONE idea") == true)
        #expect(step["how"]?.stringValue?.contains("propose_artwork_variant") == true)
    }

    @Test func aVariantNobodyAskedForIsTurnedAway() async throws {
        let outcome = try await ready().call(ProposeArtworkVariantTool(), ["run": "run-debug", "change": "Warmer", "template": ["bg": ["stops": ["#F6C38B"]]]])
        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["reason"]?.stringValue?.contains("No variant was asked for") == true)
    }

    @Test func theVariantIsRenderedAndCheckedInEveryLanguage() async throws {
        let fixtures = ready()
        fixtures.center.requestVariant(appID: MCPAutopilotFixtures.appID, role: .header, kind: .header)
        let outcome = try await fixtures.call(ProposeArtworkVariantTool(), [
            "run": "run-debug", "change": "A calm morning page instead of the editor",
            "template": ["bg": ["stops": ["#F6C38B", "#E9775A"]]],
        ])
        #expect(outcome.result["status"] == "rendered")
        #expect(outcome.result["languages"] == 2)

        let document = try await fixtures.services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS)
        let variant = try #require(document.extras?.variant)
        #expect(variant.kind == .header)
        #expect(variant.idea == "Outcome")
        #expect(variant.files.map(\.locale) == ["en-US", "de-DE"])
        #expect(variant.files.allSatisfy { $0.checks != nil }, "Each language is checked")
        #expect(variant.template.background.stops == ["#F6C38B", "#E9775A"])
        #expect(fixtures.run?.variantRequest == nil)
        #expect(try await fixtures.call(NextStepTool(), ["run": "run-debug"]).result["action"] == "done")
    }
}
#endif
