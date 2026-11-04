//
//  ArtworkDesignToolsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Claude Design designs the header and search itself: the brief tells it
/// everything AppLocalizer does with its HTML pages, propose_direction and
/// revise_direction take them (rendered and checked, refused when they
/// can't be used), render_artwork shows one in any language, and next_step
/// sends them back for changes and Product Page Optimization variants.
@MainActor
@Suite("Claude Design's header and search pages over MCP", .serialized)
struct ArtworkDesignToolsTests {
    private static let pages = JSONValue.object(StudioDebugWebArtwork.quietIndigo.pages.mapValues(JSONValue.string))

    private static func direction(_ name: String, pages: JSONValue? = Self.pages) -> [String: JSONValue] {
        var arguments: [String: JSONValue] = ["run": "run-debug", "name": .string(name), "rationale": "A night sky.", "base": "band"]
        if let pages { arguments["artworkDesign"] = pages }
        return arguments
    }

    // MARK: - get_design_brief

    @Test func theBriefTellsTheDesignerEverythingAppLocalizerDoes() async throws {
        let outcome = try await MCPAutopilotFixtures(StudioDebugExtras.run(.design)).call(GetDesignBriefTool(), ["run": "run-debug"])
        let contract = try #require(outcome.result["artworkDesign"])
        #expect(contract["youDesignIt"]?.stringValue?.contains("AppLocalizer draws nothing of its own on them") == true)
        let pages = try #require(contract["pages"]?.arrayValue)
        #expect(pages.compactMap { $0["key"]?.stringValue } == ["header", "search"])
        #expect(pages.first?["pixelSize"] == "3840 × 1646")
        #expect(pages.first?["css"]?.stringValue?.contains("width: 3840px; height: 1646px") == true)
        #expect(contract["page"]?.stringValue?.contains("No scripts (they never run)") == true)
        #expect(contract["fillIns"]?["headline"]?.stringValue?.contains("data-al-fit") == true)
        #expect(contract["fillIns"]?["capture"]?.stringValue?.contains("data-slot=\"N\"") == true)
        #expect(contract["fonts"]?.stringValue?.contains("Playfair Display") == true)
        #expect(contract["rendering"]?.stringValue?.contains("render_artwork") == true)
        #expect(contract["checks"]?.stringValue?.contains("contrast of 3:1") == true)
        #expect(contract["rightToLeft"]?.stringValue?.hasPrefix("ar-SA get dir=\"rtl\"") == true)
        #expect(contract["motion"] == "These are stills: only the start of any animation is drawn.")
        // The app's icon comes after the picks when it has one (this
        // workspace's Lumen has none to load).
        let hasIcon = outcome.result["icon"] != nil
        #expect(outcome.images.count == (hasIcon ? 6 : 5))
        #expect(outcome.result["extras"]?["how"]?.stringValue?.contains("required: the direction is refused without") == true)

        let loop = try await MCPAutopilotFixtures(StudioDebugArtMotion.artworkOnly(.design)).call(GetDesignBriefTool(), ["run": "run-debug"])
        #expect(loop.result["artworkDesign"]?["motion"]?.stringValue?.contains("each cycle dividing 20 s") == true)
        #expect(loop.result["extras"]?["video"]?.stringValue?.contains("your page's own CSS animation") == true)

        let screenshotsOnly = try await MCPAutopilotFixtures(StudioDebugRuns.run(.design)).call(GetDesignBriefTool(), ["run": "run-debug"])
        #expect(screenshotsOnly.result["artworkDesign"] == nil)
        #expect(screenshotsOnly.images.count == 5)
    }

    // MARK: - propose_direction

    @Test func aDirectionWithoutItsPagesIsRefused() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugExtras.run(.design))
        let none = try await fixtures.call(ProposeDirectionTool(), Self.direction("Night", pages: nil))
        #expect(none.result["status"] == "refused")
        #expect(none.result["reason"]?.stringValue?.hasPrefix("Send artworkDesign with a page for header and search") == true)

        let header = StudioDebugWebArtwork.quietIndigo.page(for: .header) ?? ""
        let onlyHeader = try await fixtures.call(ProposeDirectionTool(), Self.direction("Night", pages: ["header": .string(header)]))
        #expect(onlyHeader.result["reason"]?.stringValue?.hasPrefix("Send artworkDesign with a page for search:") == true)

        let wide = try await fixtures.call(ProposeDirectionTool(), Self.direction("Night", pages: ["wide": .string(header)]))
        #expect(wide.result["reason"]?.stringValue?.contains("artworkDesign.wide") == true)

        let empty = try await fixtures.call(ProposeDirectionTool(), Self.direction("Night", pages: ["header": "  ", "search": "x"]))
        #expect(empty.result["reason"]?.stringValue?.contains("the page’s HTML") == true)
        #expect(fixtures.run?.directions.count == 1, "Nothing was received")
    }

    @Test func aPageWithNoPlaceForTheTextIsRefused() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugExtras.run(.design))
        let header = StudioDebugWebArtwork.quietIndigo.page(for: .header) ?? ""
        let blank = """
        <!doctype html><html><head><style>html, body { margin: 0; width: 3840px; height: 2560px; background: #223; }</style></head>
        <body><img data-al="capture" data-slot="1" style="width: 900px"></body></html>
        """
        let outcome = try await fixtures.call(ProposeDirectionTool(), Self.direction("Night", pages: ["header": .string(header), "search": .string(blank)]))
        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["reason"]?.stringValue?.contains("The search page has no data-al=\"headline\" element") == true)
        #expect(fixtures.run?.directions.count == 1)
    }

    @Test func aDirectionsPagesAreRenderedCheckedAndKept() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugExtras.run(.design))
        let outcome = try await fixtures.call(ProposeDirectionTool(), Self.direction("Night"))

        #expect(outcome.result["status"] == "received")
        let artwork = try #require(outcome.result["artwork"]?.arrayValue)
        #expect(artwork.map { $0["kind"] } == ["header", "search"])
        #expect(artwork.allSatisfy { $0["locale"] == "en-US" })
        let search = try #require(artwork.last?["elements"]?.arrayValue)
        #expect(search.contains { $0["marker"] == "capture" && $0["slot"] == 1 && $0["loaded"] == true }, "The real pick, filled in")
        #expect(search.contains { $0["marker"] == "appName" })
        #expect(outcome.result["artworkImages"]?.stringValue?.contains("Attached in the same order") == true)
        #expect(outcome.images.count == 2)
        #expect(outcome.images.allSatisfy { $0.mimeType == "image/png" })
        #expect(fixtures.run?.directions.last?.artworkDesign?.pages == StudioDebugWebArtwork.quietIndigo.pages)
        #expect(fixtures.run?.directions.last?.artworkDesign?.phrases == ["header": [], "search": []], "Read: no phrases of their own")
    }

    // MARK: - revise_direction

    @Test func aRevisionCanSendOnlyThePageThatChanges() async throws {
        let run = StudioDebugWebArtwork.designed(StudioDebugArtMotion.revising)
        let fixtures = MCPAutopilotFixtures(run)
        let search = try #require(StudioDebugWebArtwork.fullBleed.page(for: .search))
        let outcome = try await fixtures.call(ReviseDirectionTool(), [
            "run": "run-debug", "direction": "d-1", "artworkDesign": ["search": .string(search)], "rationale": "A warmer search image.",
        ])

        #expect(outcome.result["status"] == "revised")
        #expect(outcome.result["artwork"]?.stringValue?.hasPrefix("New pages for search") == true)
        #expect(outcome.result["artworkChecks"]?.arrayValue?.map { $0["kind"] } == ["search"])
        #expect(outcome.images.count == 1)
        let direction = try #require(fixtures.run?.directions.first)
        #expect(direction.artworkDesign?.page(for: .search) == search)
        #expect(direction.artworkDesign?.page(for: .header) == StudioDebugWebArtwork.quietIndigo.page(for: .header), "The header stays")
        #expect(direction.template == run.directions[0].template, "No template change was sent")
        #expect(direction.isRevised)
    }

    @Test func aTemplateRevisionLeavesThePagesAsTheyAre() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugWebArtwork.designed(StudioDebugArtMotion.revising))
        let outcome = try await fixtures.call(ReviseDirectionTool(), [
            "run": "run-debug", "direction": "d-2", "ops": [["op": "replace", "path": "caption.headline.size", "value": 120]],
        ])
        #expect(outcome.result["artwork"] == "The header and search pages stayed exactly as they were: only artworkDesign changes them.")
        #expect(fixtures.run?.directions[1].artworkDesign == StudioDebugWebArtwork.fullBleed)
    }

    // MARK: - render_artwork

    @Test func renderArtworkShowsAPageInAnyLanguage() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugWebArtwork.designed(StudioDebugExtras.run(.design)))
        let outcome = try await fixtures.call(RenderArtworkTool(), [
            "run": "run-debug", "kind": "search", "direction": "Quiet Indigo", "locale": "de-DE", "headline": "Tagebuch für jeden ruhigen Abend",
        ])

        #expect(outcome.isError == false)
        #expect(outcome.result["kind"] == "search")
        #expect(outcome.result["locale"] == "de-DE")
        #expect(outcome.result["headline"] == "Tagebuch für jeden ruhigen Abend")
        #expect(outcome.result["headlineFits"] == true)
        let elements = try #require(outcome.result["elements"]?.arrayValue)
        #expect(elements.contains { $0["marker"] == "headline" && $0["font"] == "ui-serif" })
        #expect(elements.contains { $0["marker"] == "capture" && $0["loaded"] == true })
        #expect(outcome.result["checks"]?.arrayValue != nil)
        #expect(outcome.images.count == 1)
        #expect(outcome.logLines == [.init(target: "Lumen Journal · Autopilot · Search results", outcome: .read)])
    }

    @Test func renderArtworkSaysWhatItNeeds() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugExtras.run(.design))
        let wide = try await fixtures.call(RenderArtworkTool(), ["run": "run-debug", "kind": "wide", "html": "<p>x</p>"])
        #expect(wide.result["reason"] == "The run makes header or search, not “wide”.")
        let nothing = try await fixtures.call(RenderArtworkTool(), ["run": "run-debug", "kind": "header", "direction": "d-1"])
        #expect(nothing.result["reason"] == "Send html, or a direction that has a header page.")
        let locale = try await fixtures.call(RenderArtworkTool(), ["run": "run-debug", "kind": "header", "html": "<p>x</p>", "locale": "xx"])
        #expect(locale.result["reason"]?.stringValue?.hasPrefix("Use one of the plan’s locales") == true)

        let screenshotsOnly = try await MCPAutopilotFixtures(StudioDebugRuns.run(.design)).call(RenderArtworkTool(), ["run": "run-debug", "kind": "header"])
        #expect(screenshotsOnly.result["reason"] == "This run makes no header or search artwork.")
    }

    // MARK: - next_step

    @Test func revisingSendsEachDirectionsPages() throws {
        let run = StudioDebugWebArtwork.designed(StudioDebugArtMotion.revising)
        let json = AutopilotNextStep.revise(note: "Warmer header").mcpJSON(run: run)
        let first = try #require(json["directions"]?.arrayValue?.first)
        #expect(first["artworkDesign"]?["header"]?.stringValue == StudioDebugWebArtwork.quietIndigo.page(for: .header))
        #expect(first["artwork"] == nil, "Its pages are the artwork")
        #expect(json["artwork"]?.stringValue?.contains("sending the whole new page for each canvas") == true)
        #expect(json["motion"]?.stringValue?.contains("editing the page's @keyframes") == true)
    }

    @Test func theDesignStepSaysToSendThePages() {
        let how = AutopilotNextStep.design(remaining: 2).mcpJSON(run: nil)["how"]?.stringValue
        #expect(how?.contains("the header and search as your own HTML pages") == true)
        #expect(how?.contains("render_artwork") == true)
    }

    @Test func aVariantOfAPageIsAWholePage() async throws {
        var run = StudioDebugWebArtwork.designed(StudioDebugExtras.run(.ready))
        run.plan.localeCodes = ["en-US", "de-DE"]
        let fixtures = MCPAutopilotFixtures(run)
        let extras = StudioDebugExtras.extras(for: run)
        fixtures.services.documentChange = { $0.extras = extras }
        #expect(fixtures.center.requestVariant(appID: MCPAutopilotFixtures.appID, role: .search, kind: .search))

        let step = try await fixtures.call(NextStepTool(), ["run": "run-debug"]).result
        #expect(step["action"] == "design_variant")
        let current = try #require(step["currentPage"]?.stringValue)
        #expect(current == run.chosenDirection?.artworkDesign?.page(for: .search))
        #expect(step["how"]?.stringValue?.contains("as html: the whole page, currentPage with the one idea changed") == true)

        let template = try await fixtures.call(ProposeArtworkVariantTool(), [
            "run": "run-debug", "change": "Warmer", "ops": [["op": "replace", "path": "caption.headline.size", "value": 120]],
        ])
        #expect(template.result["reason"] == "Send html: the variant’s whole search page, next_step’s currentPage with one idea changed.")

        let warmer = current.replacingOccurrences(of: "#1b1840 0%, #3a2f7a 55%, #6a4fb0 100%", with: "#7a2f1b 0%, #c46a3a 55%, #f0b070 100%")
        let outcome = try await fixtures.call(ProposeArtworkVariantTool(), [
            "run": "run-debug", "change": "A warm dusk instead of night", "html": .string(warmer),
        ])
        #expect(outcome.result["status"] == "rendered")
        #expect(outcome.result["languages"] == 2)
        #expect(outcome.images.count == 1, "The variant as rendered in the primary language")
        let document = try await fixtures.services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS)
        let variant = try #require(document.extras?.variant)
        #expect(variant.design?.page(for: .search) == warmer)
        #expect(variant.files.map(\.locale) == ["en-US", "de-DE"])
    }

    /// A variant comes after Localize translated the pages' phrases, so a
    /// new phrase on it comes with its words in every other language.
    @Test func aVariantsNewPhraseComesInEveryLanguage() async throws {
        var run = StudioDebugWebArtwork.designed(StudioDebugExtras.run(.ready))
        run.plan.localeCodes = ["en-US", "de-DE"]
        let fixtures = MCPAutopilotFixtures(run)
        let extras = StudioDebugExtras.extras(for: run)
        fixtures.services.documentChange = { $0.extras = extras }
        #expect(fixtures.center.requestVariant(appID: MCPAutopilotFixtures.appID, role: .search, kind: .search))
        let step = try await fixtures.call(NextStepTool(), ["run": "run-debug"]).result
        #expect(step["how"]?.stringValue?.contains("send phrases [{phrase, locale, text}] in every other run language") == true)

        let current = try #require(run.chosenDirection?.artworkDesign?.page(for: .search))
        let phrase = """
        <p data-al="text" style="position: absolute; left: 400px; top: 1500px; width: 1500px; margin: 0; \
        font: 600 110px/1.1 system-ui; color: #fff">Feel  calmer</p>
        """
        let html = current.replacingOccurrences(of: "</body>", with: phrase + "</body>")
        let untranslated = try await fixtures.call(ProposeArtworkVariantTool(), [
            "run": "run-debug", "change": "The outcome in words", "html": .string(html),
        ])
        #expect(untranslated.result["status"] == "refused")
        #expect(untranslated.result["reason"]?.stringValue?.contains("phrase ‘Feel calmer’ has no words yet in de-DE") == true)

        let outcome = try await fixtures.call(ProposeArtworkVariantTool(), [
            "run": "run-debug", "change": "The outcome in words", "html": .string(html),
            "phrases": [["phrase": "Feel calmer", "locale": "de-DE", "text": "Ruhiger fühlen"]],
        ])
        #expect(outcome.result["status"] == "rendered", "\(outcome.result)")
        let document = try await fixtures.services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS)
        #expect(document.extras?.variant?.design?.phrases(for: .search) == ["Feel calmer"])
        #expect(document.artworkTexts?.phrase("Feel calmer", locale: "de-DE") == nil, "Only the variant's images carry it")
    }

    // MARK: - What the person asked

    private static func asking(_ run: AutopilotRun, _ text: String = "Show some motivational phrases") -> AutopilotRun {
        var run = run
        run.plan.alsoMakes.artworkDirection = AutopilotArtworkDirection(text: text)
        return run
    }

    /// Quiet Indigo's pages with a phrase on the search image, written
    /// once in English (or, like pages from before, a version per one of
    /// `versions`), and `extra` HTML on it.
    private static func pagesWithPhrase(versions locales: [String]? = nil, extra: String = "") -> JSONValue {
        let words = locales.map { locales in
            locales.map { "<span lang=\"\($0)\">\($0 == "en-US" ? "Small steps count." : "Small steps count (\($0)).")</span>" }.joined()
        } ?? "Small steps count."
        let phrase = """
        <p data-al="text" data-al-fit style="position: absolute; left: 400px; top: 1500px; width: 1500px; height: 200px; margin: 0; \
        font: 600 110px/1.1 system-ui; color: #fff">\(words)</p>\(extra)
        """
        var design = StudioDebugWebArtwork.quietIndigo
        design.setPage(design.page(for: .search)?.replacingOccurrences(of: "</body>", with: phrase + "</body>"), for: .search)
        return .object(design.pages.mapValues(JSONValue.string))
    }

    @Test func whatThePersonAskedComesFirstInTheBrief() async throws {
        let outcome = try await MCPAutopilotFixtures(Self.asking(StudioDebugExtras.run(.design))).call(GetDesignBriefTool(), ["run": "run-debug"])
        let contract = try #require(outcome.result["artworkDesign"])
        let asked = try #require(contract["askedByThePerson"])
        #expect(asked["expectedResult"] == "Show some motivational phrases")
        #expect(asked["priority"]?.stringValue?.contains("It outranks AppLocalizer's advice") == true)
        #expect(asked["priority"]?.stringValue?.contains("write them yourself with data-al=\"text\", once, in the primary language") == true)
        #expect(asked["references"] == nil)
        #expect(contract.objectValue?.keys.sorted().first == "askedByThePerson", "Sorted, it's the first thing in artworkDesign")
        #expect(contract["youDesignIt"]?.stringValue?.contains("each its own take on what the person asked") == true)
        let text = contract["fillIns"]?["text"]?.stringValue ?? ""
        #expect(text.contains("written once as plain text in the primary language"))
        #expect(text.contains("AppLocalizer translates each phrase at Localize"))
        #expect(text.contains("show every phrase at 0 s"), "A phrase that only fades in later leaves the poster the same in every language")
        #expect(outcome.result["extras"]?["roles"]?["header"]?.stringValue?.contains("comes before this advice") == true)

        let none = try await MCPAutopilotFixtures(StudioDebugExtras.run(.design)).call(GetDesignBriefTool(), ["run": "run-debug"])
        #expect(none.result["artworkDesign"]?["askedByThePerson"] == nil)
        #expect(none.result["extras"]?["roles"]?["header"]?.stringValue?.contains("comes before this advice") == false)
    }

    @Test func aDirectionMustSayHowItAnswersTheRequest() async throws {
        let run = Self.asking(StudioDebugExtras.run(.design))
        let fixtures = MCPAutopilotFixtures(run)
        let silent = try await fixtures.call(ProposeDirectionTool(), Self.direction("Night"))
        #expect(silent.result["status"] == "refused")
        #expect(silent.result["reason"]?.stringValue?.contains("“Show some motivational phrases”") == true)
        #expect(silent.result["reason"]?.stringValue?.contains("send followsTheRequest") == true)

        var answered = Self.direction("Night", pages: Self.pagesWithPhrase())
        answered["followsTheRequest"] = "One of their phrases over the night sky on search."
        let outcome = try await fixtures.call(ProposeDirectionTool(), answered)
        #expect(outcome.result["status"] == "received", "\(outcome.result)")
        #expect(outcome.result["followsTheRequest"] == "One of their phrases over the night sky on search.")
        let search = outcome.result["artwork"]?.arrayValue?.last?["elements"]?.arrayValue ?? []
        #expect(search.contains { $0["marker"] == "text" && $0["text"] == "Small steps count." && $0["phrase"] == "Small steps count." })
        let stored = fixtures.run?.directions.last?.artworkDesign
        #expect(stored?.phrases(for: .search) == ["Small steps count."], "The phrases Localize translates")
        #expect(stored?.phrases(for: .header) == [])
    }

    /// Phrases are written once, in the primary language: AppLocalizer
    /// translates them at Localize. Only words outside every data-al are
    /// refused, since nothing could translate them.
    @Test func aPhraseInOneLanguageIsFineWordsOutsideDataAlArent() async throws {
        let run = StudioDebugExtras.run(.design)
        let locales = run.plan.localeCodes
        #expect(locales.count > 1 && locales.first == "en-US")
        let fixtures = MCPAutopilotFixtures(run)
        let english = try await fixtures.call(ProposeDirectionTool(), Self.direction("Night", pages: Self.pagesWithPhrase()))
        #expect(english.result["status"] == "received", "\(english.result)")
        let before = fixtures.run?.directions.count

        let stray = "<p style=\"position: absolute; left: 400px; top: 1800px; font: 100px system-ui; color: #fff\">Believe in yourself</p>"
        let written = try await fixtures.call(ProposeDirectionTool(), Self.direction("Dawn", pages: Self.pagesWithPhrase(extra: stray)))
        #expect(written.result["status"] == "refused")
        #expect(written.result["reason"]?.stringValue?.contains("writes ‘Believe in yourself’ itself") == true)
        #expect(written.result["reason"]?.stringValue?.contains("written once in en-US (AppLocalizer translates them)") == true)
        #expect(fixtures.run?.directions.count == before, "Nothing was received")

        let search = Self.pagesWithPhrase(extra: stray)["search"]?.stringValue ?? ""
        let tried = try await fixtures.call(RenderArtworkTool(), ["run": "run-debug", "kind": "search", "html": .string(search)])
        let wouldBe = tried.result["wouldBeRefused"]?.arrayValue?.compactMap(\.stringValue) ?? []
        #expect(wouldBe.count == 1, "render_artwork says what propose_direction would refuse")
        #expect(tried.result["wordsOutsideDataAl"] == ["Believe in yourself"])
    }

    @Test func aPageFromBeforeWithItsOwnVersionsIsStillFine() async throws {
        let run = StudioDebugExtras.run(.design)
        let fixtures = MCPAutopilotFixtures(run)
        let outcome = try await fixtures.call(ProposeDirectionTool(), Self.direction("Night", pages: Self.pagesWithPhrase(versions: run.plan.localeCodes)))
        #expect(outcome.result["status"] == "received", "\(outcome.result)")
        let search = outcome.result["artwork"]?.arrayValue?.last?["elements"]?.arrayValue ?? []
        #expect(search.contains { $0["marker"] == "text" && $0["languages"]?.arrayValue?.count == run.plan.localeCodes.count })
        #expect(fixtures.run?.directions.last?.artworkDesign?.phrases(for: .search) == ["Small steps count."])
    }

    @Test func theStepsSayToShowWhatThePersonAsked() {
        let how = AutopilotNextStep.design(remaining: 3).mcpJSON(run: nil)["how"]?.stringValue
        #expect(how?.contains("show what the person asked, its askedByThePerson, first") == true)
        let revise = AutopilotNextStep.revise(note: "Add quotes").mcpJSON(run: StudioDebugWebArtwork.designed(StudioDebugArtMotion.revising))
        #expect(revise["artwork"]?.stringValue?.contains("go on the page as data-al=\"text\", written once in the primary language") == true)
    }
}
#endif
