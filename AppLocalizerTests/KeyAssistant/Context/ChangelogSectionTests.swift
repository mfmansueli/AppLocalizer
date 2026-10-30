//
//  ChangelogSectionTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

/// The part of CHANGELOG.md a request includes: the version's section in
/// any of the usual heading styles, else the first.
@Suite("ChangelogSection")
struct ChangelogSectionTests {
    private let markdown = """
    # Changelog

    ## [Unreleased]
    - Nothing yet.

    ## [1.4.0] - 2026-10-01
    ### Added
    - Weekly reflections.

    ## v1.3
    - Prompts.
    """

    @Test func findsTheVersionsSectionWithItsSubheadings() throws {
        let section = try #require(ChangelogSection(markdown: markdown, version: "1.4"))
        #expect(section.title == "1.4.0")
        #expect(section.text == "### Added\n- Weekly reflections.")
        #expect(ChangelogSection(markdown: markdown, version: "1.3")?.text == "- Prompts.")
    }

    @Test func withoutTheVersionItsTheFirstSection() {
        let section = ChangelogSection(markdown: markdown, version: "2.0")
        #expect(section?.title == "[Unreleased]")
        #expect(section?.text == "- Nothing yet.")
        #expect(ChangelogSection(markdown: markdown, version: nil)?.title == "[Unreleased]")
    }

    @Test func noHeadingsOrAnEmptySectionIsNothing() {
        #expect(ChangelogSection(markdown: "Just text.", version: "1.4") == nil)
        #expect(ChangelogSection(markdown: "## 1.4\n\n## 1.3\n- Prompts.", version: "1.4") == nil)
    }
}
