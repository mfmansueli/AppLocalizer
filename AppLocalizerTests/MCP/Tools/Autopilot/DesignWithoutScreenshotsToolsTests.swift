//
//  DesignWithoutScreenshotsToolsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// A run that makes no screenshots (only the header and search, or the App
/// Preview): the design AI designs only what the run makes. The brief
/// leaves the screenshot canvases and template out and says what the
/// header sits above; next_step and revise_direction say so; and a
/// direction needs no template.
@MainActor
@Suite("Designing a run without screenshots", .serialized)
struct DesignWithoutScreenshotsToolsTests {
    /// Only the header and search, at Design.
    private static var headerAndSearch: AutopilotRun {
        var run = StudioDebugExtras.run(.design, languages: .primary)
        AutopilotRunPreset.headerAndSearch.apply(to: &run.plan, devices: [.iPhone, .iPad], canReuse: true)
        return run
    }

    private static let pages = JSONValue.object(StudioDebugWebArtwork.quietIndigo.pages.mapValues(JSONValue.string))

    // MARK: - get_design_brief

    @Test func theBriefLeavesTheScreenshotsOut() async throws {
        let brief = try await MCPAutopilotFixtures(Self.headerAndSearch).call(GetDesignBriefTool(), ["run": "run-debug"]).result
        for key in ["canvases", "captions", "bases", "templateFields", "contract"] {
            #expect(brief[key] == nil, "\(key) is about the screenshots")
        }
        let note = try #require(brief["noScreenshots"]?.stringValue)
        #expect(note.contains("Design only the header and search"))
        #expect(note.contains("leave base, template and ops out"))
        #expect(brief["artworkDesign"] != nil)
        #expect(brief["picks"]?.arrayValue?.isEmpty == false, "The header and search still show the picks")
        let live = try #require(brief["liveScreenshots"], "What the header sits above")
        #expect(live["background"]?.arrayValue?.isEmpty == false)
        #expect(live["headlineFont"]?.stringValue?.isEmpty == false)
        #expect(live["says"]?.stringValue?.contains("continue these colors and this typeface") == true)
    }

    @Test func withAnAppPreviewTheTemplateIsOnlyItsLook() async throws {
        var run = StudioDebugExtras.run(.design)
        run.plan.runChoice.makesScreenshots = false
        let brief = try await MCPAutopilotFixtures(run).call(GetDesignBriefTool(), ["run": "run-debug"]).result
        #expect(brief["canvases"] == nil)
        #expect(brief["bases"] != nil)
        #expect(brief["templateFields"] != nil)
        #expect(brief["noScreenshots"]?.stringValue?.contains("only style the App Preview's captions and end card") == true)

        let screenshots = try await MCPAutopilotFixtures(StudioDebugExtras.run(.design)).call(GetDesignBriefTool(), ["run": "run-debug"]).result
        #expect(screenshots["noScreenshots"] == nil)
        #expect(screenshots["liveScreenshots"] == nil)
        #expect(screenshots["canvases"] != nil)
        #expect(screenshots["contract"] != nil)
    }

    @Test func theNoteSaysWhatEachRunDesigns() {
        let artwork = GetDesignBriefTool.noScreenshots(makesArtwork: true, stylesPreview: false)
        #expect(artwork.hasPrefix("This run makes no screenshots: the live set and its template stay as they are."))
        let preview = GetDesignBriefTool.noScreenshots(makesArtwork: false, stylesPreview: true)
        #expect(preview.hasPrefix("This run makes no screenshots, only the App Preview"))
        #expect(preview.contains("the look of the App Preview's captions and end card"))
    }

    // MARK: - next_step

    @Test func theDesignStepAsksOnlyForThePages() {
        let how = AutopilotNextStep.design(remaining: 3).mcpJSON(run: Self.headerAndSearch)["how"]?.stringValue ?? ""
        #expect(how.contains("this run makes no screenshots (the live set stays), so only the header and search as your own HTML pages"))
        #expect(how.contains("show what the person asked, its askedByThePerson, first"))
        #expect(how.contains("No screenshot template: leave base, template and ops out."))
        #expect(!how.contains("the screenshots as an AppLocalizer template"))

        var preview = StudioDebugExtras.run(.design)
        AutopilotRunPreset.appPreview.apply(to: &preview.plan, devices: [.iPhone, .iPad], canReuse: true)
        let previewHow = AutopilotNextStep.design(remaining: 3).mcpJSON(run: preview)["how"]?.stringValue ?? ""
        #expect(previewHow.contains("the template (template and/or ops on a base starter) is the App Preview's captions and end card"))

        let screenshots = AutopilotNextStep.design(remaining: 3).mcpJSON(run: StudioDebugExtras.run(.design))["how"]?.stringValue ?? ""
        #expect(screenshots.contains("the screenshots as an AppLocalizer template"))
    }

    @Test func aRevisionIsAboutThePages() throws {
        let json = AutopilotNextStep.revise(note: "Bigger phrases").mcpJSON(run: StudioDebugWebArtwork.artworkOnly(.design))
        let first = try #require(json["directions"]?.arrayValue?.first)
        #expect(first["template"] == nil, "No screenshots, no App Preview: nothing uses it")
        #expect(first["artworkDesign"]?["header"]?.stringValue == StudioDebugWebArtwork.quietIndigo.page(for: .header))
        #expect(json["noScreenshots"]?.stringValue?.contains("Send only their pages, no template.") == true)

        let screenshots = AutopilotNextStep.revise(note: "x").mcpJSON(run: StudioDebugWebArtwork.designed(StudioDebugArtMotion.revising))
        #expect(screenshots["noScreenshots"] == nil)
        #expect(screenshots["directions"]?.arrayValue?.first?["template"] != nil)
    }

    // MARK: - propose_direction and revise_direction

    @Test func aDirectionIsOnlyItsPages() async throws {
        let fixtures = MCPAutopilotFixtures(Self.headerAndSearch)
        let outcome = try await fixtures.call(ProposeDirectionTool(), [
            "run": "run-debug", "name": "Night", "rationale": "A night sky.", "artworkDesign": Self.pages,
        ])

        #expect(outcome.result["status"] == "received", "\(outcome.result)")
        #expect(outcome.result["checks"] == [], "No screenshot captions to fit")
        let run = try #require(fixtures.run)
        #expect(run.directions.last?.artworkDesign?.pages == StudioDebugWebArtwork.quietIndigo.pages)
        #expect(run.directions.last?.artworkDesign?.hasReadPhrases == true, "Its phrases are read as it's received")
        #expect(run.log.contains { $0.text == "Direction 2 · Night → header and search sent to AppLocalizer" }, "\(run.log.suffix(3).map(\.text))")
    }

    @Test func aRevisedDirectionSaysWhatWasSent() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugWebArtwork.artworkOnly(.design))
        let search = try #require(StudioDebugWebArtwork.fullBleed.page(for: .search))
        let outcome = try await fixtures.call(ReviseDirectionTool(), [
            "run": "run-debug", "direction": "d-1", "artworkDesign": ["search": .string(search)], "last": false,
        ])

        #expect(outcome.result["status"] == "revised", "\(outcome.result)")
        let run = try #require(fixtures.run)
        let name = try #require(run.directions.first?.name)
        #expect(run.log.last?.text == "\(name) revised → header and search sent to AppLocalizer; more on the way")
    }
}
#endif
