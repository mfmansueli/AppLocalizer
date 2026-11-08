//
//  AppKnowledgeTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// What's worth asking about an app, and how new answers join old ones.
@Suite("What's known about an app")
struct AppKnowledgeTests {
    private static let now = Date(timeIntervalSince1970: 1_800_000_000)
    private static let day: TimeInterval = 24 * 60 * 60

    @Test func everythingIsAskedAtFirst() {
        #expect(AppKnowledge().isEmpty)
        #expect(AppKnowledge().due(now: Self.now) == AppQuestion.allCases)
    }

    @Test func anAnswerIsntAskedAgain() {
        var knowledge = AppKnowledge()
        knowledge.set(.soundMood, text: "  Quiet and warm \n", by: "Claude Code", at: Self.now)
        #expect(knowledge.answer(to: .soundMood) == "Quiet and warm")
        #expect(!knowledge.due(now: Self.now).contains(.soundMood))
        #expect(knowledge.due(now: Self.now).count == AppQuestion.allCases.count - 1)
    }

    /// "The project doesn't say" is an answer: it isn't asked every run.
    @Test func aBlankAnswerCountsAsAsked() {
        var knowledge = AppKnowledge()
        knowledge.set(.voice, text: "   ", by: nil, at: Self.now)
        #expect(knowledge.answer(to: .voice) == nil)
        #expect(!knowledge.due(now: Self.now).contains(.voice))
    }

    @Test func anOldAnswerIsAskedAgain() {
        var knowledge = AppKnowledge()
        knowledge.set(.difference, text: "Offline first", by: nil, at: Self.now)
        #expect(!knowledge.due(now: Self.now.addingTimeInterval(120 * Self.day)).contains(.difference))
        #expect(knowledge.due(now: Self.now.addingTimeInterval(121 * Self.day)).contains(.difference))
    }

    @Test func newerAnswersWinAndTheRestStays() {
        var older = AppKnowledge()
        older.set(.voice, text: "Plain", by: nil, at: Self.now)
        older.set(.offLimits, text: "No medical claims", by: nil, at: Self.now)
        older.music = AppMusicPick(track: .calmPiano, reason: "Calm")
        var newer = AppKnowledge()
        newer.set(.voice, text: "Warm", by: nil, at: Self.now)

        let merged = older.merging(newer)
        #expect(merged.answer(to: .voice) == "Warm")
        #expect(merged.answer(to: .offLimits) == "No medical claims")
        #expect(merged.music?.track == .calmPiano, "A newer report without music leaves it")

        newer.music = AppMusicPick(track: .softAmbient, reason: "Quiet")
        #expect(older.merging(newer).music?.track == .softAmbient)
    }

    /// Answers are kept by raw value, so a later version can drop a
    /// question without losing the file.
    @Test func anAnswerToADroppedQuestionStillLoads() throws {
        let saved = #"{"answers":{"retired":{"text":"Old","answeredAt":0},"voice":{"text":"Plain","answeredAt":0}}}"#
        let knowledge = try JSONDecoder().decode(AppKnowledge.self, from: Data(saved.utf8))
        #expect(knowledge.answer(to: .voice) == "Plain")
        #expect(knowledge.music == nil)
    }
}
