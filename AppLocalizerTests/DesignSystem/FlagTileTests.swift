//
//  FlagTileTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("FlagTile")
struct FlagTileTests {
    @Test func regionCodesBecomeFlagEmoji() {
        #expect(FlagTile.flag(for: "BR") == "🇧🇷")
        #expect(FlagTile.flag(for: "jp") == "🇯🇵")
    }

    @Test(arguments: ["", "B", "EU1", "B1", "BRA"])
    func anythingElseFallsBackToTheCode(code: String) {
        #expect(FlagTile.flag(for: code) == nil)
    }
}
