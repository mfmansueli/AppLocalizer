//
//  DesignProjectNameTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The design project's name in the strip's pill, the stage list and the
/// plan: what was read from it, or a short form of its link, never a whole
/// URL that wraps down the sheet.
@Suite("DesignProject · display name")
struct DesignProjectNameTests {
    @Test func aClaudeDesignLinkIsShortened() {
        let project = DesignProject(
            kind: .claudeDesign, link: "https://claude.ai/artifact/KxcpHYisJkSjAC2sXf7QHN?org=495d75b4-465a-42bc-b378-4fb6c09e5b2d"
        )
        #expect(project.displayName == "claude.ai/artifact/KxcpHYis…")
    }

    @Test func aFigmaLinkShowsTheFilesName() {
        let project = DesignProject(kind: .figma, link: "https://www.figma.com/design/AbC123xyz456/Lumen-Brand?node-id=0-1")
        #expect(project.displayName == "Lumen Brand")
    }

    @Test func aShortLinkKeepsItsPath() {
        #expect(DesignProject(kind: .figma, link: "https://www.example.com/brand").displayName == "example.com/brand")
        #expect(DesignProject(kind: .figma, link: "https://figma.com/file/lumen").displayName == "figma.com/file/lumen")
    }

    @Test func whatWasReadWins() {
        var project = DesignProject(kind: .claudeDesign, link: "https://claude.ai/artifact/KxcpHYisJkSjAC2sXf7QHN")
        project.summary = DesignSourceSummary(title: "Alba Brand · design system")
        #expect(project.displayName == "Alba Brand")
    }

    @Test func namesAndFoldersAreUnchanged() {
        #expect(DesignProject(kind: .claudeDesign, link: "Northpier Brand · Claude Design").displayName == "Northpier Brand")
        #expect(DesignProject(kind: .folder, link: "/Users/me/Brand Kit").displayName == "Brand Kit")
        #expect(DesignProject(kind: .claudeDesign, link: "").displayName == "Claude Design")
    }
}
