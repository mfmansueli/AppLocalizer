//
//  TemplateHistoryTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Each save, accepted proposal or restore makes a version; the content
/// hash ignores the version number and the name.
@MainActor
@Suite("TemplateHistory")
struct TemplateHistoryTests {
    private let date = Date(timeIntervalSince1970: 1_790_000_000)

    private var template: ScreenshotTemplate {
        get throws { try ScreenshotTemplateJSONTests.decode() }
    }

    @Test func theHashIsStableAndIgnoresVersionAndName() throws {
        let original = try template
        var renamed = original
        renamed.version = 9
        renamed.name = "Something else"
        #expect(original.contentHash == renamed.contentHash)
        #expect(try original.contentHash == (ScreenshotTemplateJSONTests.decode()).contentHash)
        var changed = original
        changed.caption.headline.size = 110
        #expect(changed.contentHash != original.contentHash)
    }

    @Test func savingMakesTheNextVersion() throws {
        var history = try TemplateHistory.starting(with: template, date: date, note: "Start")
        #expect(history.currentNumber == 1)
        var next = try template
        next.caption.headline.size = 100
        let saved = history.save(next, date: date, note: "Smaller")
        #expect(saved?.number == 2)
        #expect(history.currentTemplate?.caption.headline.size == 100)
    }

    @Test func savingTheSameTemplateMakesNoVersion() throws {
        var history = try TemplateHistory.starting(with: template, date: date, note: "Start")
        #expect(try history.save(template, date: date, note: "Again") == nil)
        #expect(history.versions.count == 1)
    }

    @Test func aProposalOnTheCurrentVersionIsAcceptedAsTheAssistant() throws {
        var history = try TemplateHistory.starting(with: template, date: date, note: "Start")
        let result = history.accept([.replace("caption.headline.size", with: 104)], basedOn: 1, from: "Claude Code", reason: "Room", date: date)
        let version = try result.get()
        #expect(version.number == 2)
        #expect(version.author == .assistant(client: "Claude Code"))
        #expect(version.assistant == "Claude Code")
    }

    @Test func aProposalOnAnOlderVersionIsStale() throws {
        var history = try TemplateHistory.starting(with: template, date: date, note: "Start")
        var next = try template
        next.caption.headline.size = 100
        history.save(next, date: date, note: "Smaller")
        let result = history.accept([.replace("caption.headline.size", with: 104)], basedOn: 1, from: "Claude Code", reason: "Room", date: date)
        guard case let .failure(refusals) = result else {
            Issue.record("Expected a stale refusal")
            return
        }
        #expect(refusals.items.map(\.kind) == [.stale])
        #expect(history.currentNumber == 2)
    }

    @Test func restoringMakesANewVersionFromAnOldOne() throws {
        var history = try TemplateHistory.starting(with: template, date: date, note: "Start")
        var next = try template
        next.caption.headline.size = 100
        history.save(next, date: date, note: "Smaller")
        let restored = history.restore(1, date: date)
        #expect(restored?.number == 3)
        #expect(restored?.restoredFrom == 1)
        #expect(history.currentTemplate?.caption.headline.size == 112)
        #expect(history.versions.count == 3)
    }

    #if DEBUG
    @Test func theSampleHistoryEndsAtTheSampleTemplate() {
        let history = ScreenshotsSampleData.history
        #expect(history.currentNumber == 4)
        #expect(history.currentTemplate?.contentHash == ScreenshotsSampleData.template.contentHash)
        #expect(history.current?.assistant == "Claude Code")
    }
    #endif
}
