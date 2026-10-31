//
//  BrandFolderReaderTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Reading a brand folder on this Mac: colors from `tokens.json`, font
/// files and an SVG logo.
@Suite("Brand folder reader")
struct BrandFolderReaderTests {
    private let folder: URL

    init() throws {
        folder = URL.temporaryDirectory.appending(path: "BrandFolderReaderTests-\(UUID().uuidString)/Northpier Brand", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    private func write(_ text: String, to name: String) throws {
        try Data(text.utf8).write(to: folder.appending(path: name))
    }

    @Test func colorsFontsAndTheLogoAreRead() throws {
        try write(
            """
            {
              "color": {
                "brand": { "indigo": { "value": "#5b5bd6" }, "dusk": { "$value": "#2E2A6B" } },
                "ink": "#1C1A33",
                "overlay": "#1C1A3380",
                "named": "blue",
                "short": "#FFF"
              }
            }
            """,
            to: "tokens.json"
        )
        for name in ["SF Pro Text.otf", "New York Bold.ttf", "notes.txt"] {
            try write("", to: name)
        }
        try write("<svg/>", to: "moon-mark.svg")

        let summary = try BrandFolderReader.summary(of: folder, now: .distantPast)
        #expect(summary.title == "Northpier Brand · brand folder")
        #expect(summary.readBy == "AppLocalizer")
        #expect(summary.colors == [
            DesignSwatch(name: "Dusk", hex: "#2E2A6B"), DesignSwatch(name: "Indigo", hex: "#5B5BD6"),
            DesignSwatch(name: "Ink", hex: "#1C1A33"), DesignSwatch(name: "Overlay", hex: "#1C1A3380"),
        ])
        #expect(summary.typefaces == "New York Bold · SF Pro Text")
        #expect(summary.logo == "moon-mark.svg")
        #expect(summary.updated != nil)
    }

    @Test func atMostSixColorsAreKept() {
        let tokens = (1...9).map { "\"c\($0)\": \"#00000\($0)\"" }.joined(separator: ", ")
        let colors = BrandFolderReader.colors(in: Data("{\(tokens)}".utf8))
        #expect(colors.map(\.name) == ["C1", "C2", "C3", "C4", "C5", "C6"])
        #expect(BrandFolderReader.colors(in: Data("not json".utf8)).isEmpty)
    }

    @Test func aFolderWithOnlyFontsIsEnough() throws {
        try write("", to: "Northpier.ttc")
        let summary = try BrandFolderReader.summary(of: folder)
        #expect(summary.colors.isEmpty)
        #expect(summary.typefaces == "Northpier")
        #expect(summary.logo == nil)
    }

    @Test func aFolderWithNothingBrandedIsRefused() throws {
        try write("Read me", to: "README.md")
        try write(#"{"spacing": {"small": 4}}"#, to: "tokens.json")
        #expect(throws: AutopilotError("No tokens.json, fonts or SVG logo in Northpier Brand.")) {
            try BrandFolderReader.summary(of: folder)
        }
    }
}
