//
//  DesignBriefPersonNoteTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// get_design_brief's personNote: what the person told the designer at
/// Look reaches the screenshot directions, not only the header.
@MainActor
@Suite("get_design_brief · the person's note")
struct DesignBriefPersonNoteTests {
    private static func brief(_ change: (inout AutopilotPlan) -> Void) -> [String: JSONValue] {
        var run = StudioDebugGuided.started(StudioDebugExtras.run(.design, languages: .primary))
        change(&run.plan)
        var result: [String: JSONValue] = [:]
        GetDesignBriefTool.addPersonNote(&result, run: run)
        return result
    }

    @Test func theScreenshotDirectionsFollowTheNote() {
        let result = Self.brief { $0.alsoMakes.artworkDirection.text = "  Calm, like writing before bed " }
        guard case let .object(note)? = result["personNote"] else {
            Issue.record("No personNote")
            return
        }
        #expect(note["text"] == .string("Calm, like writing before bed"))
        #expect(note["says"]?.stringValue?.contains("Every screenshot direction follows it") == true)
        #expect(note["references"] == nil)
    }

    @Test func referencesAreNamed() {
        let reference = AutopilotArtworkReference(fileID: "abc.png", name: "moodboard.png")
        let result = Self.brief { $0.alsoMakes.artworkDirection.references = [reference] }
        guard case let .object(note)? = result["personNote"], case let .array(references)? = note["references"] else {
            Issue.record("No references")
            return
        }
        #expect(note["text"] == nil)
        #expect(references == [.object(["name": .string("moodboard.png"), "kind": .string("image")])])
    }

    @Test func noNoteOrNoScreenshotsToDesignSaysNothing() {
        #expect(Self.brief { _ in }["personNote"] == nil)
        #expect(Self.brief {
            $0.alsoMakes.artworkDirection.text = "Calm"
            $0.screenshotStyle = .keep
        }["personNote"] == nil, "Keeping the look: no screenshot direction to design")
        #expect(Self.brief {
            $0.alsoMakes.artworkDirection.text = "Calm"
            $0.runChoice.makesScreenshots = false
        }["personNote"] == nil, "artworkDesign's askedByThePerson has it")
    }
}
#endif
