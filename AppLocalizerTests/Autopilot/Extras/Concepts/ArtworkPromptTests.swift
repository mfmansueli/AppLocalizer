//
//  ArtworkPromptTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The header and search prompts: each a resource file of its own, filled
/// at run time (shared blocks, the run's values, "unknown" for a value
/// nobody gave), without what asks for a place the run doesn't make, and
/// logged with their id, version and hash.
@MainActor
@Suite("Header and search prompts")
struct ArtworkPromptTests {
    // MARK: - The files

    @Test(arguments: ArtworkPromptID.allCases)
    func everyPromptIsAResourceFile(_ id: ArtworkPromptID) {
        let text = ArtworkPromptLibrary.text(id)
        #expect(!text.isEmpty, "\(id.rawValue).txt is in the app")
        #expect(!text.contains("BEGIN PROMPT") && !text.contains("END PROMPT"), "Only the prompt's own text")
    }

    @Test func theConceptsPromptsIncludeTheSharedBlocks() {
        for id in [ArtworkPromptID.conceptsFree, .conceptsTemplates] {
            let keys = ArtworkPromptFiller.keys(in: ArtworkPromptLibrary.text(id))
            #expect(keys.contains("block:app-context"), "\(id.rawValue)")
            #expect(keys.contains("block:reference-headers"), "\(id.rawValue)")
        }
    }

    // MARK: - Filling

    @Test func aValueNobodyGaveReadsUnknown() {
        let filled = ArtworkPromptFiller.filling("For {{app_name}}, in {{locale}}; {{ empty }}{{open", with: ["app_name": "Lumen", " empty ": "  "])
        #expect(filled == "For Lumen, in unknown; unknown{{open")
    }

    @Test func blocksAreFilledToo() {
        let texts: [ArtworkPromptID: String] = [
            .conceptsFree: "Start\n{{block:app-context}}\n{{block:reference-headers}}\nEnd",
            .appContext: "App: {{app_name}}", .referenceHeaders: "References",
        ]
        let filler = ArtworkPromptFiller(values: ["app_name": "Lumen"], size: .headerAndSearch) { texts[$0] ?? "" }
        #expect(filler.fill(.conceptsFree) == "Start\nApp: Lumen\nReferences\nEnd")
    }

    @Test func aHeaderOnlyRunLeavesOutTheSearchParts() {
        let text = """
        Places:
        - Header: 3840 × 1646.
          - Calm top.
        - Search results: 3840 × 2560.
          - The capture at the inline end.
        - 16:9: 5244 × 2950.
        Search: 1 phrase of 2–5 words. Header: at most 1 phrase, or none ("the app name only"). End.
        "search_layout": "…",
        """
        let header = ArtworkPromptFiller.leavingOut(text, size: .headerOnly)
        #expect(header.contains("- Header: 3840 × 1646.\n  - Calm top."))
        #expect(!header.contains("Search results") && !header.contains("inline end") && !header.contains("16:9"))
        #expect(!header.contains("search_layout"))
        #expect(header.contains("Header: at most 1 phrase") && !header.contains("Search: 1 phrase"))

        let search = ArtworkPromptFiller.leavingOut(text, size: .searchOnly)
        #expect(!search.contains("- Header:") && search.contains("- Search results:"))
        #expect(search.contains("Search: 1 phrase") && !search.contains("Header: at most"))

        #expect(ArtworkPromptFiller.leavingOut(text, size: .wide) == text, "The 16:9 image is both")
        #expect(!ArtworkPromptFiller.leavingOut(text, size: .headerAndSearch).contains("16:9"))
    }

    // MARK: - The run's prompts

    private static func builder(_ run: AutopilotRun) -> ArtworkPromptBuilder {
        ArtworkPromptBuilder(run: run, facts: ArtworkPromptFacts(ageRating: "4+", captions: [0: "Write a little every day"]), appName: "Lumen Journal")
    }

    @Test func fromTemplatesTheConceptsPromptNamesThePicks() {
        let prompt = Self.builder(StudioDebugHeaderStyle.headerOnly(.design)).concepts()
        #expect(prompt.id == .conceptsTemplates)
        #expect(prompt.version == "v4")
        #expect(prompt.text.contains("night"))
        #expect(prompt.text.contains("Lumen"))
        #expect(!prompt.text.contains("{{"))
        #expect(prompt.hash.count == 64)

        let free = Self.builder(StudioDebugHeaderStyle.headerOnly(.design, style: .free)).concepts()
        #expect(free.id == .conceptsFree)
        #expect(free.text.contains("Calm, like writing before bed"), "What the person asked")
    }

    @Test func eachConceptsPagesPromptCarriesItsJSON() {
        var concept = StudioDebugConcepts.fromTemplates[1]
        concept.json = #"{"id":"B","name":"Evening Hills"}"#
        let prompt = Self.builder(StudioDebugHeaderStyle.headerOnly(.design)).pages(for: concept)
        #expect(prompt.id == .pages)
        #expect(prompt.about == "B")
        #expect(prompt.text.contains(#"{"id":"B","name":"Evening Hills"}"#))
        #expect(prompt.mcpJSON["for"] == "B")
    }

    @Test func theNoteIsAppendedToThePromptItChanges() {
        let builder = Self.builder(StudioDebugHeaderStyle.headerOnly(.choose))
        let concept = StudioDebugConcepts.fromTemplates[0]
        let motion = builder.motion(for: concept)
        #expect(motion.id == .motion)
        #expect(motion.text.contains("pages.header and pages.search below, as you sent them"))
        let change = builder.change("Slower movement", targets: [concept], after: motion)
        #expect(change.id == .change)
        #expect(change.text.hasPrefix(motion.text))
        #expect(change.text.contains("Slower movement"))
        #expect(change.text.contains("A (Moonrise)"))
    }

    @Test func nextStepHandsOutOnlyWhatsLeft() {
        var run = StudioDebugHeaderStyle.headerOnly(.design)
        run.concepts = Array(run.conceptList.prefix(1))
        let prompts = NextStepTool.prompts(for: .design(remaining: 0), run: run, builder: Self.builder(run))
        #expect(prompts.map(\.id) == [.conceptsTemplates], "One concept came with its pages; the others' ideas are still to come")

        var idea = StudioDebugConcepts.fromTemplates[1]
        idea.design = nil
        run.concepts?.append(idea)
        #expect(NextStepTool.prompts(for: .design(remaining: 0), run: run, builder: Self.builder(run)).map(\.about) == [nil, "B"])

        let all = StudioDebugHeaderStyle.headerOnly(.design)
        #expect(NextStepTool.prompts(for: .design(remaining: 0), run: all, builder: Self.builder(all)).isEmpty)
    }

    // MARK: - The log

    @Test func everyPromptAndAnswerIsLogged() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "prompt-log-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        var run = StudioDebugHeaderStyle.headerOnly(.design)
        run.concepts = nil
        let fixtures = MCPAutopilotFixtures(run)
        fixtures.center.promptLog = ArtworkPromptLog(url: folder.appending(path: "ArtworkPrompts.jsonl"))
        _ = try await fixtures.call(NextStepTool(), ["run": "run-debug"])
        _ = try await fixtures.call(ProposeArtworkConceptTool(), [
            "run": "run-debug",
            "concept": ["id": "A", "name": "Moonrise", "template": "night", "metaphor": "A moon rising.", "fits_because": "The icon is a moon."],
        ])

        let entries = try #require(fixtures.center.promptLog?.entries())
        let prompt = try #require(entries.first)
        #expect(prompt.event == .prompt)
        #expect(prompt.promptID == "artwork-concepts-templates")
        #expect(prompt.promptVersion == "v4")
        #expect(prompt.provider == "Claude Code")
        #expect(prompt.designSource == "Claude Design")
        #expect(prompt.promptHash?.count == 64)
        #expect(prompt.inputs?["app_name"]?.isEmpty == false)
        let answer = try #require(entries.last)
        #expect(answer.event == .answer)
        #expect(answer.about == "A")
        #expect(answer.outputs?["tool"] == "propose_artwork_concept")
        #expect(answer.outputs?["concept"]?.contains("Moonrise") == true)
    }
}
#endif
