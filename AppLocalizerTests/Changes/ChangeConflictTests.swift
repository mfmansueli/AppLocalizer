//
//  ChangeConflictTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("Change conflicts")
struct ChangeConflictTests {
    private let claude = ChangeSource.assistant(client: "Claude Code")

    @Test func theAssistantsDifferentVersionBecomesTheAlternative() {
        let queue = ChangeQueue()
        queue.upsert(PushFixtures.listing("WhatsNew", new: "Mine"))
        queue.upsert(PushFixtures.listing("WhatsNew", new: "Claude's", source: claude))
        let change = queue.change(id: "listing.de.WhatsNew")
        #expect(change?.newValue == "Mine")
        #expect(change?.source == .you)
        #expect(change?.alternative?.newValue == "Claude's")
        #expect(change?.isBlocked == true)
        #expect(change?.blockingMessage == "You and Claude Code both changed this field.")
    }

    @Test func thePersonsVersionStaysPrimaryWhicheverCameFirst() {
        let queue = ChangeQueue()
        queue.upsert(PushFixtures.listing("WhatsNew", new: "Claude's", source: claude))
        queue.upsert(PushFixtures.listing("WhatsNew", new: "Mine"))
        #expect(queue.change(id: "listing.de.WhatsNew")?.newValue == "Mine")
        #expect(queue.change(id: "listing.de.WhatsNew")?.alternative?.source == claude)
    }

    @Test func theSameValueOrTheSameSourceJustReplaces() {
        let queue = ChangeQueue()
        queue.upsert(PushFixtures.listing("WhatsNew", new: "Same"))
        queue.upsert(PushFixtures.listing("WhatsNew", new: "Same", source: claude))
        #expect(queue.change(id: "listing.de.WhatsNew")?.alternative == nil)
        queue.upsert(PushFixtures.listing("WhatsNew", new: "Newer", source: claude))
        queue.upsert(PushFixtures.listing("WhatsNew", new: "Newest", source: claude))
        #expect(queue.change(id: "listing.de.WhatsNew")?.newValue == "Newest")
    }

    @Test func editingAgainKeepsTheOpenDecision() {
        let queue = ChangeQueue()
        queue.upsert(PushFixtures.listing("WhatsNew", new: "Mine"))
        queue.upsert(PushFixtures.listing("WhatsNew", new: "Claude's", source: claude))
        queue.upsert(PushFixtures.listing("WhatsNew", new: "Mine, edited"))
        #expect(queue.change(id: "listing.de.WhatsNew")?.alternative?.newValue == "Claude's")
    }

    @Test(arguments: [false, true])
    func pickingAVersionResolvesIt(keepAlternative: Bool) {
        let queue = ChangeQueue()
        queue.upsert(PushFixtures.listing("WhatsNew", new: "Mine"))
        queue.upsert(PushFixtures.listing("WhatsNew", new: "Claude's", source: claude))
        queue.resolveAlternative(id: "listing.de.WhatsNew", keepAlternative: keepAlternative)
        let change = queue.change(id: "listing.de.WhatsNew")
        #expect(change?.alternative == nil)
        #expect(change?.newValue == (keepAlternative ? "Claude's" : "Mine"))
        #expect(change?.source == (keepAlternative ? claude : .you))
        #expect(change?.isBlocked == false)
    }

    @Test func rejectingAnAssistantClearsItsAlternatives() {
        let queue = ChangeQueue()
        queue.upsert(PushFixtures.listing("WhatsNew", new: "Mine"))
        queue.upsert(PushFixtures.listing("WhatsNew", new: "Claude's", source: claude))
        queue.upsert(PushFixtures.listing("Name", new: "Claude's name", source: claude))
        queue.rejectAll(fromAssistant: "Claude Code")
        #expect(queue.changes.map(\.id) == ["listing.de.WhatsNew"])
        #expect(queue.changes.first?.alternative == nil)
    }

    @Test func keepingMineAcceptsTheRemoteValueAsTheNewBaseline() {
        let queue = ChangeQueue()
        var change = PushFixtures.price("BRA")
        change.conflictCheck = ConflictCheck(path: "/check", keyPath: ["value"], expected: "219.9")
        queue.upsert(change)
        queue.markRemoteConflict(id: change.id, RemoteConflict(remoteRawValue: "199.9", remoteDisplayValue: "R$ 199,90"))
        #expect(queue.change(id: change.id)?.isBlocked == true)

        queue.keepMine(id: change.id)
        let kept = queue.change(id: change.id)
        #expect(kept?.remoteConflict == nil)
        #expect(kept?.conflictCheck?.expected == "199.9")
        #expect(kept?.oldValue == "R$ 199,90")
        #expect(kept?.isBlocked == false)
    }

    @Test func usingTheRemoteValueDropsTheChange() {
        let queue = ChangeQueue()
        queue.upsert(PushFixtures.price("BRA"))
        queue.useRemote(id: "price.annual.BRA")
        #expect(queue.changes.isEmpty)
    }
}
