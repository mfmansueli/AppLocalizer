//
//  TemplateDiffTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// What changed between two templates, and the version note it makes.
@Suite("TemplateDiff")
struct TemplateDiffTests {
    private let template = ScreenshotsSampleData.template

    @Test func noChangesSaysSo() {
        #expect(TemplateDiff.changes(from: template, to: template).isEmpty)
        #expect(TemplateDiff.note(for: []) == "No changes")
    }

    @Test func upToThreeChangesAreNamedInSchemaOrder() {
        var edited = template
        edited.fit.hyphenate = true
        edited.caption.headline.size = 104
        let changes = TemplateDiff.changes(from: template, to: edited)
        #expect(changes.map(\.path) == ["caption.headline.size", "fit.hyphenate"])
        #expect(TemplateDiff.note(for: changes) == "Headline size 104 u, hyphenation on")
    }

    @Test func moreThanThreeChangesAreCounted() {
        var edited = template
        edited.fit.hyphenate = true
        edited.caption.headline.size = 104
        edited.device.width = 0.74
        edited.background.angle = 120
        let changes = TemplateDiff.changes(from: template, to: edited)
        #expect(changes.count == 4)
        #expect(TemplateDiff.note(for: changes) == "Gradient angle, Device width and 2 more changes")
    }

    @Test func slotLayoutsAndOverridesAreChangesOfTheirSlot() throws {
        var edited = template
        edited.slots[2].layout = .hero
        edited.slots[1].over = [:]
        let changes = TemplateDiff.changes(from: template, to: edited)
        #expect(changes.map(\.path) == ["slots.1.over.caption.headline.size", "slots.2.layout"])
        let override = try #require(changes.first)
        #expect(override.slot == 1)
        #expect(override.fieldPath == "caption.headline.size")
        #expect(override.oldText == "104 u")
        #expect(override.newText == "as the template")
        #expect(changes[1].title == "Slot 3 layout")
    }

    @Test func valuesReadAsTheInspectorShowsThem() {
        #expect(TemplateSchema.formatted(.double(0.74), at: "device.width") == "74%")
        #expect(TemplateSchema.formatted(.double(168), at: "bg.angle") == "168°")
        #expect(TemplateSchema.formatted(nil, at: "fonts.fallback.thai") == "none")
        #expect(TemplateSchema.title(for: "fonts.fallback.thai") == "Thai fallback")
        #expect(TemplateSchema.title(for: "caption.headline.min") == "Headline smallest size")
    }
}
#endif
