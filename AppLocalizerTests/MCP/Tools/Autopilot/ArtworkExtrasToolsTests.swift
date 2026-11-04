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
        #expect(header.contains("Brand first: usually the app name and at most one short line"))
        #expect(header.contains("a device is optional"))
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
        #expect(stillRows == ["Header · 21:9", "Search results · 3:2", "Safe area", "One look for both", "About the app", "Still image", "Words"])

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
            "Header · 21:9", "Search results · 3:2", "Safe area", "One look for both", "About the app", "Motion · 20-second loop",
            "Poster, loop and sound", "Your direction", "Words",
        ])
        let search = rows.first { $0["rule"] == "Search results · 3:2" }?["says"]?.stringValue
        #expect(search?.contains("a scene in the brand’s style, with no app screens and no device") == true)
        let motion = rows.first { $0["rule"] == "Motion · 20-second loop" }?["says"]?.stringValue
        #expect(motion?.contains("float") == false, "A scene has no phone to float")
    }

    /// Each canvas says its safe area in its own pixels and what covers
    /// the rest, and the rule says only the background goes there.
    @Test func theBriefGivesEachCanvasItsSafeArea() async throws {
        let brief = try await MCPAutopilotFixtures(StudioDebugExtras.run(.design)).call(GetDesignBriefTool(), ["run": "run-debug"]).result
        let extras = try #require(brief["extras"])
        let canvases = try #require(extras["canvases"]?.arrayValue)
        let header = try #require(canvases.first?["safeArea"])
        #expect(header["x"] == 653)
        #expect(header["y"] == 362)
        #expect(header["width"] == 2534)
        #expect(header["height"] == 1284)
        let outside = try #require(header["outside"]?.stringValue)
        #expect(outside.contains("The outer 17% on each side, which iPhone crops"))
        #expect(outside.contains("the top 22%, where the status bar, Back and Share sit"))
        let search = try #require(canvases.last?["safeArea"])
        #expect(search["width"] == 3840)
        #expect(search["outside"]?.stringValue?.hasPrefix("Nothing is cropped") == true)

        let rule = try #require(extras["safeArea"]?.stringValue)
        #expect(rule.contains("only the background (color, gradient, texture, the scene) runs to the edges"))
        #expect(rule.contains("center the focal point in it, not in the canvas"))
        #expect(rule.contains("about 40% longer"))
        let role = try #require(extras["roles"]?["header"]?.stringValue)
        #expect(role.contains("(17% is cut on each side)"))
        #expect(role.contains("the top 22%"))

        let wide = try await MCPAutopilotFixtures(StudioDebugExtras.run(.design, size: .wide)).call(GetDesignBriefTool(), ["run": "run-debug"]).result
        #expect(wide["extras"]?["bothCrops"]?.stringValue?.contains("the header cuts 17% off each side and the top 12%") == true)
        #expect(wide["extras"]?["canvases"]?.arrayValue?.first?["safeArea"]?["y"] == 354)
    }

    @Test func theSafeAreaRowSaysWhereTheTextGoes() {
        let header = AutopilotArtworkBrief.safeAreaRow(AutopilotExtras(makesArtwork: true))
        #expect(header.title == "Safe area")
        #expect(header.text.hasPrefix("On the header, keep the app name, every line of text and the phones inside the middle 66% of the width"))
        #expect(header.text.contains("and below the top 22%"))
        #expect(header.text.contains("keep text a little in from them"))

        var scene = AutopilotExtras(makesArtwork: true)
        scene.artworkShows = .scene
        scene.artworkSize = .wide
        let wide = AutopilotArtworkBrief.safeAreaRow(scene)
        #expect(wide.text.hasPrefix("Keep the app name, every line of text and the scene’s focal point inside the middle 66% of the width"))
        #expect(wide.text.contains("and below the top 12%"))
    }

    @Test func percentInsetsRoundTheSafeArea() {
        let header = ArtworkSafeArea.percentInsets(for: .header)
        #expect(header.top == 22)
        #expect(header.side == 17)
        let wide = ArtworkSafeArea.percentInsets(for: .wide)
        #expect(wide.top == 12)
        #expect(wide.side == 17)
        let search = ArtworkSafeArea.percentInsets(for: .search)
        #expect(search.top == 0)
        #expect(search.side == 0)
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

    /// The words to start each language's headline from, from its page.
    @Test func theTextsStartFromEachLanguagesSearchWords() async throws {
        let outcome = try await MCPAutopilotFixtures(localizing).call(NextStepTool(), ["run": "run-debug"])
        let words = try #require(outcome.result["startFrom"]?.arrayValue)
        #expect(words.map { $0["locale"] } == ["de-DE"], "Only the languages it asks for")
        #expect(words.first?["subtitle"] == "Private Notizen, sanfte Fragen")
        #expect(words.first?["keywords"]?.arrayValue?.isEmpty == false)
        #expect(outcome.result["how"]?.stringValue?.contains("startFrom") == true)
    }

    /// The brief says what the app is in its own words, and the artwork's
    /// part says to use it.
    @Test func theBriefSaysWhatTheAppIs() async throws {
        let brief = try await MCPAutopilotFixtures(StudioDebugExtras.run(.design)).call(GetDesignBriefTool(), ["run": "run-debug"]).result
        let about = try #require(brief["aboutTheApp"])
        #expect(about["subtitle"] == "Private notes, gentle prompts")
        #expect(about["categories"]?.arrayValue?.first == "Lifestyle")
        #expect(about["description"]?.stringValue?.isEmpty == false)
        #expect(about["languages"]?.arrayValue?.first?["locale"] == "en-US")
        #expect(about["languages"]?.arrayValue?.first?["keywords"]?.arrayValue?.contains("diary") == true)
        #expect(about["iconColors"] == nil, "This workspace's Lumen has no icon (AutopilotAppProfileTests has the colors)")
        #expect(about["useIt"]?.stringValue?.contains("Design for this app") == true)
        #expect(brief["extras"]?["aboutTheApp"]?.stringValue?.contains("not its category") == true)
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
        #expect(step["safeArea"]?["x"] == 653, "The variant keeps the header's safe area")
        #expect(step["how"]?.stringValue?.contains("stay inside safeArea") == true)
    }

    /// The sheet's "read what to change": when next_step first hands the
    /// request over, not again.
    @Test func readingTheRequestIsRecordedOnce() async throws {
        let fixtures = ready()
        fixtures.center.requestVariant(appID: MCPAutopilotFixtures.appID, role: .header, kind: .header)
        #expect(fixtures.run?.variantRequest?.readAt == nil)
        _ = try await fixtures.call(NextStepTool(), ["run": "run-debug"])
        let read = try #require(fixtures.run?.variantRequest?.readAt)
        _ = try await fixtures.call(NextStepTool(), ["run": "run-debug"])
        #expect(fixtures.run?.variantRequest?.readAt == read)
        #expect(fixtures.run?.log.filter { $0.text.contains("read what to change") }.count == 1)
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
