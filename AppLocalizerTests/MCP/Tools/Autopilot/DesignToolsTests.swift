//
//  DesignToolsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The design AI's tools: `get_design_brief`, `propose_direction`,
/// `revise_direction` and `report_design_source`.
@MainActor
@Suite("Autopilot design tools")
struct DesignToolsTests {
    private static let biggerHeadline: JSONValue = [["op": "replace", "path": "caption.headline.size", "value": 120]]

    // MARK: - get_design_brief

    @Test func theBriefHasThePicksCaptionsCanvasesAndBrand() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.design), project: StudioDebugRuns.northpier)
        let outcome = try await fixtures.call(GetDesignBriefTool(), ["run": "run-debug"])
        let brief = outcome.result

        #expect(brief["run"] == "run-debug")
        #expect(brief["app"] == "Lumen Journal")
        #expect(brief["picks"]?.arrayValue?.count == 5)
        #expect(brief["picks"]?.arrayValue?.first == [
            "slot": 1, "screen": "today", "name": "Today", "pixelSize": "1320 × 2868", "notes": "Prompt card and three moods; no keyboard",
        ])
        #expect(outcome.images.count == 5)
        #expect(outcome.images.allSatisfy { $0.mimeType == "image/png" })
        #expect(brief["rightToLeft"] == ["ar-SA"])
        #expect(brief["directions"] == 3)
        #expect(brief["bases"]?.arrayValue?.map { $0["base"]?.stringValue } == TemplateStarter.allCases.map(\.rawValue))
        #expect(brief["bases"]?.arrayValue?.last?["style"] == "playful")
        #expect(brief["templateFields"]?.arrayValue?.contains("caption.headline.size") == true)
        #expect(brief["canvases"]?.arrayValue?.map { $0["displayType"] } == ["iphone", "ipad"])
        #expect(brief["canvases"]?.arrayValue?.first?["safeArea"]?["width"]?.intValue ?? 0 > 0)
        #expect(brief["designProject"] == ["kind": "claudeDesign", "source": "Northpier Brand · Claude Design", "createDirectionsThere": true])
        #expect(brief["directionsSoFar"] == [["id": "d-1", "name": "Quiet Indigo"]])
        #expect(brief["revisionNote"] == nil)
        #expect(outcome.logLines == [.init(target: "Lumen Journal · Autopilot", outcome: .read)])
    }

    @Test func eachSlotsCaptionsComeWithTheLongest() async throws {
        let brief = try await MCPAutopilotFixtures(StudioDebugRuns.run(.design)).call(GetDesignBriefTool()).result
        let slots = try #require(brief["captions"]?.arrayValue)
        #expect(slots.count == 5)
        let search = try #require(slots.first { $0["slot"] == 3 })
        #expect(search["screen"] == "Search")
        let captions = try #require(search["captions"]?.arrayValue)
        #expect(captions.count == 12)
        let longest = try #require(captions.max { ($0["length"]?.intValue ?? 0) < ($1["length"]?.intValue ?? 0) })
        #expect(search["longest"]?["length"] == longest["length"])
        #expect(captions.allSatisfy { $0["length"]?.intValue == $0["headline"]?.stringValue?.count })
    }

    @Test func anUnreadProjectAsksToBeReadAndARevisionCarriesItsNote() async throws {
        var project = StudioDebugRuns.northpier
        project.summary = nil
        var run = StudioDebugRuns.run(.design)
        run.revision = AutopilotRevisionRequest(note: "A lighter indigo", askedAt: AutopilotTestFixtures.now)
        let brief = try await MCPAutopilotFixtures(run, project: project).call(GetDesignBriefTool()).result
        #expect(brief["designProject"]?["readFirst"]?.stringValue?.contains("report_design_source") == true)
        #expect(brief["revisionNote"] == "A lighter indigo")
    }

    // MARK: - propose_direction

    @Test func aDirectionIsReceivedWithItsLanguageChecks() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.design))
        let outcome = try await fixtures.call(ProposeDirectionTool(), [
            "run": "run-debug", "name": "Night Band", "rationale": "Dusk band under the capture.", "base": "band",
            "ops": Self.biggerHeadline, "sourceLink": "https://claude.ai/design/northpier-brand/night-band",
        ])

        #expect(outcome.result["status"] == "received")
        let id = try #require(outcome.result["direction"]?.stringValue)
        #expect(id.hasPrefix("d-"))
        #expect(outcome.result["received"] == 2)
        #expect(outcome.result["of"] == 3)
        #expect(outcome.result["checks"]?.arrayValue?.isEmpty == false)
        #expect(outcome.logLines == [.init(target: "Lumen Journal · Autopilot · Night Band", outcome: .proposed)])
        let direction = try #require(fixtures.run?.directions.last)
        #expect(direction.id == id)
        #expect(direction.source == .claudeDesign)
        #expect(direction.client == "Claude Code")
        #expect(direction.link == "https://claude.ai/design/northpier-brand/night-band")
        #expect(direction.template.caption.headline.size == 120)
        #expect(direction.template.slots.count == 5)
        #expect(direction.checks.map(\.title) == outcome.result["checks"]?.arrayValue?.compactMap(\.stringValue))
    }

    @Test func theThirdDirectionGoesToThePersonToChoose() async throws {
        var run = StudioDebugRuns.run(.design)
        run.directions = Array(StudioDebugRuns.directions(design: true, of: run).prefix(2))
        let fixtures = MCPAutopilotFixtures(run)
        let outcome = try await fixtures.call(ProposeDirectionTool(), [
            "run": "run-debug", "name": "Dawn", "rationale": "One gradient.", "base": "panorama",
        ])
        #expect(outcome.result["received"] == 3)
        #expect(fixtures.run?.stage == .choose)

        let late = try await fixtures.call(ProposeDirectionTool(), ["run": "run-debug", "name": "Late", "rationale": "x", "base": "above"])
        #expect(late.result == ["status": "refused", "reason": "The run isn’t designing now. Call next_step to see what AppLocalizer wants."])
    }

    @Test func aDirectionThatDoesntApplyIsRefused() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.design))
        let unknownField = try await fixtures.call(ProposeDirectionTool(), [
            "run": "run-debug", "name": "Glow", "rationale": "x", "ops": [["op": "replace", "path": "caption.glow", "value": true]],
        ])
        #expect(unknownField.result["status"] == "refused")
        #expect(unknownField.result["reason"]?.stringValue?.contains("caption.glow") == true)

        let empty = try await fixtures.call(ProposeDirectionTool(), ["run": "run-debug", "name": "Empty", "rationale": "x"])
        #expect(empty.result["reason"] == "The argument “template” must be a template (as get_template returns it), ops, or a base starter.")

        let names = TemplateStarter.allCases.map(\.rawValue).formatted(.list(type: .or))
        await #expect(throws: MCPToolError.invalidArgument(name: "base", expected: names)) {
            try await fixtures.call(ProposeDirectionTool(), ["run": "run-debug", "name": "Spiral", "rationale": "x", "base": "spiral"])
        }
        #expect(fixtures.run?.directions.count == 1)
    }

    @Test func aTemplatesFieldsAreLaidOnTheBase() throws {
        let base = ScreenshotTemplate.starter(.above, id: "lumen", title: "Lumen")
        let current = try #require(base.value(at: "caption.headline.size"))
        let json: JSONValue = ["caption": ["headline": ["size": current, "maxLines": 3]], "glow": true]
        let operations = MCPDirectionTemplate.operations(from: json, over: base)
        #expect(operations == [.replace("caption.headline.maxLines", with: 3)], "Unchanged and unknown fields are left out")
    }

    @Test func aDirectionCanChangeOneSlot() {
        let base = ScreenshotTemplate.starter(.cinema, id: "lumen", title: "Lumen")
        let tilt: JSONValue = ["rz": 4, "ry": -10, "rx": 6]
        let json: JSONValue = ["slots": [["layout": "hero"], ["over": ["device.tilt": tilt]], ["over": .object(base.slots[2].over)]]]
        let operations = MCPDirectionTemplate.operations(from: json, over: base)
        #expect(operations == [.replace("slots.1.over.device.tilt", with: tilt)], "Slot 1 is already hero; slot 3 is unchanged")
    }

    // MARK: - revise_direction

    @Test func aRevisionIsSentBackToTheChoice() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.choose))
        fixtures.center.requestRevision("Bigger headline", appID: MCPAutopilotFixtures.appID)
        let outcome = try await fixtures.call(ReviseDirectionTool(), [
            "run": "run-debug", "direction": "quiet indigo", "ops": Self.biggerHeadline, "rationale": "Bigger, as asked.",
        ])

        #expect(outcome.result == ["status": "revised", "direction": "d-1"])
        #expect(outcome.logLines == [.init(target: "Lumen Journal · Autopilot · Quiet Indigo", outcome: .proposed)])
        let run = try #require(fixtures.run)
        #expect(run.stage == .choose)
        #expect(run.directions[0].isRevised)
        #expect(run.directions[0].template.caption.headline.size == 120)
        #expect(run.directions[0].rationale == "Bigger, as asked.")
    }

    @Test func aRevisionNobodyAskedForOrOfAnUnknownDirectionIsRefused() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.choose))
        let unasked = try await fixtures.call(ReviseDirectionTool(), ["run": "run-debug", "direction": "d-1", "ops": Self.biggerHeadline])
        #expect(unasked.result["reason"] == "No change was asked for. Call next_step to see what AppLocalizer wants.")

        let unknown = try await fixtures.call(ReviseDirectionTool(), ["run": "run-debug", "direction": "Neon", "ops": Self.biggerHeadline])
        #expect(unknown.result["reason"] == "No direction “Neon” in this run; it has d-1 (Quiet Indigo), d-2 (Full Bleed), or d-3 (Dawn Panorama).")
        #expect(fixtures.run?.directions.contains { $0.isRevised } == false)
    }

    // MARK: - report_design_source

    @Test func whatTheAssistantFoundInTheProjectIsShown() async throws {
        var project = StudioDebugRuns.northpier
        project.summary = nil
        let fixtures = MCPAutopilotFixtures(project: project)
        let outcome = try await fixtures.call(ReportDesignSourceTool(), [
            "title": "Northpier Brand · design system",
            "colors": [["name": "Indigo", "hex": "#5b5bd6"], ["name": "Sky", "hex": "not-a-color"], ["name": "Ink"]],
            "typefaces": "New York Bold for headlines", "logo": "Moon mark", "voice": "Calm, short sentences",
        ])

        #expect(outcome.result == ["status": "saved"])
        #expect(outcome.logLines == [.init(target: "Lumen Journal · Design project", outcome: .proposed)])
        let summary = try #require(fixtures.center.designProject(for: MCPAutopilotFixtures.appID)?.summary)
        #expect(summary.title == "Northpier Brand · design system")
        #expect(summary.colors == [DesignSwatch(name: "Indigo", hex: "#5B5BD6")])
        #expect(summary.typefaces == "New York Bold for headlines")
        #expect(summary.logo == "Moon mark")
        #expect(summary.voice == "Calm, short sentences")
        #expect(summary.readBy == "Claude Code")
    }

    @Test func withoutAProjectThereIsNothingToReport() async throws {
        let outcome = try await MCPAutopilotFixtures().call(ReportDesignSourceTool(), ["title": "Northpier Brand"])
        #expect(outcome.result == [
            "status": "refused",
            "reason": "Lumen Journal has no design project connected. The person connects one in Screenshots → Design project.",
        ])
    }
}
#endif
