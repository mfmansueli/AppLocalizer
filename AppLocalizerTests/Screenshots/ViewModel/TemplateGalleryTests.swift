//
//  TemplateGalleryTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The template gallery: every template previewed on five slots, filtered
/// by style, each card saying which scripts its font draws, and switching
/// keeping captions as a new version.
@MainActor
@Suite("Template gallery")
struct TemplateGalleryTests {
    @Test func everyTemplateIsPreviewedOnFiveSlots() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel(ScreenshotsDebugDocuments.document(for: .noTemplate))
        #expect(model.starterPreviews.map(\.starter) == TemplateStarter.allCases)
        #expect(model.starterPreviews.allSatisfy { $0.jobs.count == StarterPreview.slotCount })
        #expect(StarterPreview.slotCount == 5)
    }

    @Test func theCountFollowsTheStyle() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        #expect(model.galleryCount == "14 templates · previewed with Lumen’s captions and captures")
        model.galleryStyle = .elegant
        #expect(model.galleryCount == "3 templates · previewed with Lumen’s captions and captures")
        #expect(TemplateStarter.starters(in: model.galleryStyle).map(\.title) == ["Cinema", "Spotlight", "Editorial"])
    }

    @Test func theFontNoteSaysWhatFallsBack() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        let anton = model.fontNote(for: "Anton", scripts: [.latin, .japanese])
        #expect(anton.hasPrefix("Anton (bundled) draws Latin"))
        #expect(anton.hasSuffix("Japanese uses a fallback font."))
        let system = model.fontNote(for: "SF Pro Display", scripts: [.latin, .cyrillic])
        #expect(!system.contains("bundled"))
        #expect(!system.contains("fallback"))
    }

    @Test func switchingFromTheGalleryIsANewVersion() async throws {
        let (model, services) = await ScreenshotsTestFixtures.viewModel()
        let captions = model.document?.captions
        await model.chooseStarter(.highlight)
        let saved = try #require(services.saved.last)
        #expect(saved.template?.starter == .highlight)
        #expect(saved.template?.name == "Lumen · Highlight")
        #expect(saved.history?.currentNumber == 5)
        #expect(saved.history?.current?.note == "Switched to the template “Highlight”")
        #expect(saved.captions == captions)
    }
}
#endif
