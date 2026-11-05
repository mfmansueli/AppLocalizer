//
//  ArtworkConceptToolsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Header concepts over MCP: next_step hands the design AI the prompts,
/// propose_artwork_concept takes each concept (its idea, then its pages,
/// rendered and checked), propose_direction no longer takes the header and
/// search in such a run, and revise_artwork_concept takes a concept's
/// changes and the chosen header's animated pages.
@MainActor
@Suite("Header concepts over MCP", .serialized)
struct ArtworkConceptToolsTests {
    private static let pages = JSONValue.object(StudioDebugWebArtwork.quietIndigo.pages.mapValues(JSONValue.string))

    /// Design in a header-only run from the picked templates, before any
    /// concept arrived.
    private static var designing: AutopilotRun {
        var run = StudioDebugHeaderStyle.headerOnly(.design)
        run.concepts = nil
        return run
    }

    private static let moonrise: JSONValue = [
        "id": "A", "name": "Moonrise", "template": "night",
        "metaphor": "The crescent from Lumen’s icon rises in a clear evening sky.",
        "fits_because": "Ties the header to the icon people see right next to it.",
        "cycle": ["type": "day-night", "beats": ["0s: dusk", "5s: moonrise", "10s: stars", "15s: dawn", "same as 0s"]],
        "phrases": ["header": nil, "search": "Write the day down"],
    ]

    // MARK: - propose_artwork_concept

    @Test func aRunFromBeforeConceptsSendsThemWithTheDirection() async throws {
        let outcome = try await MCPAutopilotFixtures(StudioDebugExtras.run(.design)).call(
            ProposeArtworkConceptTool(), ["run": "run-debug", "concept": Self.moonrise]
        )
        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["reason"] == "This run started before header concepts: send the header and search with propose_direction’s artworkDesign.")
    }

    @Test func aConceptsIdeaComesFirstThenItsPages() async throws {
        let fixtures = MCPAutopilotFixtures(Self.designing)
        let idea = try await fixtures.call(ProposeArtworkConceptTool(), ["run": "run-debug", "concept": Self.moonrise, "recommended": true])
        #expect(idea.result["status"] == "received")
        #expect(idea.result["received"] == 1)
        #expect(idea.result["designed"] == 0)
        #expect(idea.result["of"] == 3)
        #expect(idea.result["next"]?.stringValue?.contains("header and search still to come") == true)
        let concept = try #require(fixtures.run?.concept("A"))
        #expect(concept.template == .night && concept.isRecommended)
        #expect(concept.beats == ["Dusk", "Moonrise", "Stars", "Dawn"], "Times and the closing “same as” are left out")
        #expect(concept.loopLine == "Loop: Dusk → Moonrise → Stars → Dawn")

        let designed = try await fixtures.call(
            ProposeArtworkConceptTool(), ["run": "run-debug", "concept": ["id": "A"], "artworkDesign": Self.pages]
        )
        #expect(designed.result["status"] == "received", "\(designed.result)")
        #expect(designed.result["designed"] == 1)
        #expect(designed.result["artwork"]?.arrayValue?.count == 2)
        #expect(fixtures.run?.concept("A")?.design?.page(for: .header) != nil)
        #expect(fixtures.run?.concept("A")?.metaphor == "The crescent from Lumen’s icon rises in a clear evening sky.")
    }

    @Test func aConceptMustAdaptAPickedTemplate() async throws {
        let fixtures = MCPAutopilotFixtures(Self.designing)
        var concept = Self.moonrise.objectValue ?? [:]
        concept["template"] = "hero"
        let outcome = try await fixtures.call(ProposeArtworkConceptTool(), ["run": "run-debug", "concept": .object(concept)])
        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["reason"]?.stringValue?.hasPrefix("Each concept adapts one of the person’s templates") == true)

        concept["template"] = "night"
        concept["metaphor"] = nil
        let noMetaphor = try await fixtures.call(ProposeArtworkConceptTool(), ["run": "run-debug", "concept": .object(concept)])
        #expect(noMetaphor.result["reason"]?.stringValue?.contains("metaphor and fits_because") == true)
        #expect(fixtures.run?.conceptList.isEmpty == true)
    }

    @Test func whenThePersonAskedForSomethingTheConceptSaysHow() async throws {
        var run = Self.designing
        run.plan.alsoMakes.artworkDirection.text = "Calm, like writing before bed"
        let fixtures = MCPAutopilotFixtures(run)
        let outcome = try await fixtures.call(ProposeArtworkConceptTool(), ["run": "run-debug", "concept": Self.moonrise])
        #expect(outcome.result["status"] == "refused")

        let follows = try await fixtures.call(
            ProposeArtworkConceptTool(),
            ["run": "run-debug", "concept": Self.moonrise, "followsTheRequest": "A quiet night: the hour people write."]
        )
        #expect(follows.result["status"] == "received")
        #expect(fixtures.run?.concept("A")?.followsTheRequest == "A quiet night: the hour people write.")
    }

    // MARK: - propose_direction

    @Test func theDirectionNoLongerCarriesTheHeaderAndSearch() async throws {
        var run = StudioDebugHeaderStyle.choosingBoth
        run.stage = .design
        run.directions = []
        run.concepts = nil
        let fixtures = MCPAutopilotFixtures(run)
        let outcome = try await fixtures.call(ProposeDirectionTool(), [
            "run": "run-debug", "name": "Night", "rationale": "A night sky.", "base": "band", "artworkDesign": Self.pages,
        ])
        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["reason"]?.stringValue?.hasPrefix("In this run the header and search are concepts of their own") == true)

        let plain = try await fixtures.call(ProposeDirectionTool(), ["run": "run-debug", "name": "Night", "rationale": "A night sky.", "base": "band"])
        #expect(plain.result["status"] != "refused", "\(plain.result)")
        #expect(plain.result["of"] == 3)
        #expect(fixtures.run?.directions.count == 1)
        #expect(fixtures.run?.stage == .design, "The concepts are still to come")
    }

    // MARK: - next_step

    @Test func nextStepHandsOverTheConceptsPromptThenEachPagesPrompt() async throws {
        let fixtures = MCPAutopilotFixtures(Self.designing)
        let first = try await fixtures.call(NextStepTool(), ["run": "run-debug"])
        #expect(first.result["action"] == "design")
        #expect(first.result["concepts"]?["expected"] == 3)
        let prompts = try #require(first.result["prompts"]?.arrayValue)
        #expect(prompts.compactMap { $0["id"]?.stringValue } == ["artwork-concepts-templates"])
        let text = try #require(prompts.first?["text"]?.stringValue)
        #expect(text.contains("Make one concept per template"))
        #expect(!text.contains("{{"), "Every placeholder is filled")
        #expect(prompts.first?["version"]?.stringValue?.isEmpty == false)

        _ = try await fixtures.call(ProposeArtworkConceptTool(), ["run": "run-debug", "concept": Self.moonrise])
        let next = try await fixtures.call(NextStepTool(), ["run": "run-debug"])
        let ids = (next.result["prompts"]?.arrayValue ?? []).compactMap { $0["id"]?.stringValue }
        #expect(ids == ["artwork-concepts-templates", "artwork-pages"])
        #expect(next.result["prompts"]?.arrayValue?.last?["for"] == "A")
    }

    @Test func aRunFromBeforeConceptsGetsNoPrompts() async throws {
        let outcome = try await MCPAutopilotFixtures(StudioDebugExtras.run(.design)).call(NextStepTool(), ["run": "run-debug"])
        #expect(outcome.result["prompts"] == nil)
        #expect(outcome.result["concepts"] == nil)
    }

    @Test func theBriefSaysTheHeaderComesAsConcepts() async throws {
        let outcome = try await MCPAutopilotFixtures(Self.designing).call(GetDesignBriefTool(), ["run": "run-debug"])
        let contract = try #require(outcome.result["artworkDesign"])
        #expect(contract["youDesignIt"]?.stringValue?.contains("never in propose_direction") == true)
        #expect(contract["style"] == "templates")
        #expect(contract["templates"] == ["night", "land", "window"])
        #expect(contract["motion"] == "loop")
        #expect(contract["marks"] == ["appName", "text", "capture", "icon"])
        #expect(contract["fillIns"]?["headline"] == nil)
        #expect(outcome.result["directions"] == 0, "Only the header and search: no direction")

        var styled = StudioDebugRuns.run(.design)
        styled.plan.screenshotStyle = .templates
        styled.plan.screenshotTemplates = ["Cinema", "Editorial"]
        let shots = try await MCPAutopilotFixtures(styled).call(GetDesignBriefTool(), ["run": "run-debug"])
        #expect(shots.result["shot_style"] == "templates")
        #expect(shots.result["shot_templates"] == ["Cinema", "Editorial"])
        #expect(shots.result["shotStyleSays"]?.stringValue?.contains("Make one direction per template") == true)
        #expect(shots.result["directions"] == 2)
    }

    // MARK: - revise_artwork_concept

    @Test func aConceptsChangesGoBackToChoose() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugHeaderStyle.headerOnly(.choose))
        fixtures.center.requestConceptChanges("Warmer sky", conceptIDs: ["B"], forDirections: false, appID: MCPAutopilotFixtures.appID)
        let wrong = try await fixtures.call(ReviseArtworkConceptTool(), ["run": "run-debug", "concept_id": "A"])
        #expect(wrong.result["status"] == "refused")
        #expect(wrong.result["reason"]?.stringValue?.contains("not this concept") == true)

        let outcome = try await fixtures.call(
            ReviseArtworkConceptTool(), ["run": "run-debug", "concept_id": "Evening Hills", "artworkDesign": Self.pages, "change_notes": "A warmer sky"]
        )
        #expect(outcome.result["status"] == "revised", "\(outcome.result)")
        #expect(fixtures.run?.stage == .choose)
        #expect(fixtures.run?.concept("B")?.changeNotes == "A warmer sky")
    }

    // MARK: - Each concept animated at Design

    /// The header page alone, for a Header 21:9 only run.
    private static let headerPage = JSONValue.object(["header": .string(StudioDebugWebArtwork.quietIndigo.page(for: .header) ?? "")])

    @Test func eachConceptsLoopComesAtDesign() async throws {
        var run = Self.designing
        run.animatesConcepts = true
        let fixtures = MCPAutopilotFixtures(run)
        _ = try await fixtures.call(ProposeArtworkConceptTool(), ["run": "run-debug", "concept": Self.moonrise])
        _ = try await fixtures.call(ProposeArtworkConceptTool(), ["run": "run-debug", "concept": ["id": "A"], "artworkDesign": Self.pages])
        #expect(fixtures.run?.stage == .design)

        let step = try await fixtures.call(NextStepTool(), ["run": "run-debug"])
        let prompts = step.result["prompts"]?.arrayValue ?? []
        #expect(prompts.compactMap { $0["id"]?.stringValue } == ["artwork-concepts-templates", "artwork-motion"])
        #expect(prompts.last?["for"] == "A")
        #expect(prompts.last?["text"]?.stringValue?.hasPrefix("Animate this concept's pages") == true)
        let received = step.result["concepts"]?["received"]?.arrayValue?.first
        #expect(received?["loopToCome"] == true)
        #expect(received?["pages"]?["header"] != nil, "The stills its motion prompt animates")
        #expect(step.result["concepts"]?["how"]?.stringValue?.contains("the person chooses among the 20-second loops") == true)

        let brief = try await fixtures.call(GetDesignBriefTool(), ["run": "run-debug"])
        #expect(brief.result["artworkDesign"]?["motionHow"]?.stringValue?.contains("The person chooses among the loops.") == true)

        let outcome = try await fixtures.call(ReviseArtworkConceptTool(), ["run": "run-debug", "concept_id": "A", "artworkDesign": Self.pages])
        #expect(outcome.result["status"] == "animated", "\(outcome.result)")
        #expect(outcome.result["next"]?.stringValue?.hasPrefix("Its loop is in.") == true)
        #expect(fixtures.run?.concept("A")?.motion?.page(for: .header) == StudioDebugWebArtwork.quietIndigo.page(for: .header))
        #expect(fixtures.run?.stage == .design, "Two concepts to come")
    }

    @Test func aNoteOnAMovingConceptAsksForItsLoopAgain() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugHeaderStyle.headerLoopOnly)
        fixtures.center.requestConceptChanges("Warmer light", conceptIDs: ["B"], forDirections: false, appID: MCPAutopilotFixtures.appID)
        let revised = try await fixtures.call(
            ReviseArtworkConceptTool(), ["run": "run-debug", "concept_id": "B", "artworkDesign": Self.headerPage, "change_notes": "Warmer light"]
        )
        #expect(revised.result["status"] == "revised", "\(revised.result)")
        #expect(fixtures.run?.stage == .design)

        let step = try await fixtures.call(NextStepTool(), ["run": "run-debug"])
        #expect(step.result["action"] == "revise")
        let prompt = step.result["prompts"]?.arrayValue?.first
        #expect(prompt?["id"] == "artwork-change")
        #expect(prompt?["text"]?.stringValue?.hasPrefix("Animate this concept's pages") == true, "Its motion prompt, with the note")
        #expect(step.result["concepts"]?.arrayValue?.first?["animatedForThisNote"] == false)

        let animated = try await fixtures.call(ReviseArtworkConceptTool(), ["run": "run-debug", "concept_id": "B", "artworkDesign": Self.headerPage])
        #expect(animated.result["status"] == "animated", "\(animated.result)")
        #expect(fixtures.run?.stage == .choose)
        #expect(fixtures.run?.revision == nil)
    }

    @Test func theChosenHeadersAnimatedPagesMakeTheLoop() async throws {
        var run = StudioDebugHeaderStyle.headerOnly(.choose)
        run.stage = .localize
        run.art = "A"
        var review = AutopilotLoopReview(conceptID: "A")
        review.waitsToMake = true
        run.loopReview = review
        let fixtures = MCPAutopilotFixtures(run, holdsStages: true)

        let step = try await fixtures.call(NextStepTool(), ["run": "run-debug"])
        #expect(step.result["action"] == "animate_header")
        #expect((step.result["prompts"]?.arrayValue ?? []).compactMap { $0["id"]?.stringValue } == ["artwork-motion"])

        let other = try await fixtures.call(ReviseArtworkConceptTool(), ["run": "run-debug", "concept_id": "B", "artworkDesign": Self.pages])
        #expect(other.result["status"] == "refused")

        let outcome = try await fixtures.call(ReviseArtworkConceptTool(), ["run": "run-debug", "concept_id": "A", "artworkDesign": Self.pages])
        #expect(outcome.result["status"] == "animated", "\(outcome.result)")
        #expect(fixtures.run?.loopReview?.version == 1)
        #expect(fixtures.run?.loopReview?.waitsToMake == false)
        #expect(fixtures.run?.concept("A")?.motion?.page(for: .header) == StudioDebugWebArtwork.quietIndigo.page(for: .header))
        #expect(fixtures.run?.log.last?.text == "Claude Code animated the Moonrise header → loop v1 sent to AppLocalizer")
    }
}
#endif
