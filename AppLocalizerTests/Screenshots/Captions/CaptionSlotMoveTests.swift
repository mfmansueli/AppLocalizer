//
//  CaptionSlotMoveTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Captions follow their screen when a run puts the set in a new order:
/// Alba's 1.1.0 run moved Animated scenes from slot 4 to slot 2, and 13
/// languages went live with the Styles caption on it.
@Suite("CaptionSlotMove")
struct CaptionSlotMoveTests {
    private static let albaBefore = ["Today's phrase", "Styles", "Streak", "Animated scenes", "Topics"]
    private static let albaAfter = ["Today's phrase", "Animated scenes", "Styles", "Streak", "Topics", "My Phrases"]

    @Test func aScreenThatMovedTakesItsCaptionsAlong() {
        let move = CaptionSlotMove(from: Self.albaBefore, to: Self.albaAfter)
        #expect(move.sources == [0, 3, 1, 2, 4, nil])
        #expect(!move.isIdentity)

        var book = CaptionBook()
        let before = [
            "A new phrase every morning", "Make every phrase look like yours", "Build a daily habit", "Wake up to animated scenes", "Pick what inspires you",
        ]
        for (slot, headline) in before.enumerated() {
            book.setCaption(ScreenshotCaption(headline: headline), locale: "en-AU", slot: slot)
        }
        book.move(move)
        #expect(book.caption(locale: "en-AU", slot: 1)?.headline == "Wake up to animated scenes")
        #expect(book.caption(locale: "en-AU", slot: 2)?.headline == "Make every phrase look like yours")
        #expect(book.caption(locale: "en-AU", slot: 3)?.headline == "Build a daily habit")
        #expect(book.caption(locale: "en-AU", slot: 5) == nil, "My Phrases is new: its caption gets written")
    }

    @Test func aScreenRenamedWhereItStoodKeepsItsCaptions() {
        let move = CaptionSlotMove(from: ["Today", "Week", "Search"], to: ["Today", "This week", "Search"])
        #expect(move.sources == [0, 1, 2])
        #expect(move.isIdentity)
    }

    @Test func namesMatchWithoutCaseOrSpaces() {
        let move = CaptionSlotMove(from: ["Today", "Week"], to: [" week", "TODAY"])
        #expect(move.sources == [1, 0])
    }

    @Test func aRemovedScreensCaptionsAreDropped() {
        let move = CaptionSlotMove(from: ["Today", "Week", "Search"], to: ["Today", "Search"])
        #expect(move.sources == [0, 2])
        var book = CaptionBook()
        book.setCaption(ScreenshotCaption(headline: "Die Woche"), locale: "de-DE", slot: 1)
        book.setCaption(ScreenshotCaption(headline: "Suchen"), locale: "de-DE", slot: 2)
        book.move(move)
        #expect(book.caption(locale: "de-DE", slot: 1)?.headline == "Suchen")
        #expect(book.caption(locale: "de-DE", slot: 2) == nil)
    }

    @Test func aScreenAddedAtTheEndMovesNothing() {
        let move = CaptionSlotMove(from: ["Today", "Week"], to: ["Today", "Week", "Photos"])
        #expect(move.sources == [0, 1, nil])
        #expect(move.isIdentity)
    }
}
