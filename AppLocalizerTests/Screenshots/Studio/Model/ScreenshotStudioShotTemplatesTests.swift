//
//  ScreenshotStudioShotTemplatesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The plan's Screenshot style from templates: the picks shown as
/// previews, numbered in order, chosen in the template picker (a fourth
/// replacing the last), and the previews the picker and the plan show.
@MainActor
@Suite("ScreenshotStudioModel · screenshot templates")
struct ScreenshotStudioShotTemplatesTests {
    private var appID: StoreApp.ID { StudioTestFixtures.app.id }

    /// Lumen's plan with Cinema and Editorial picked. Keep the view model
    /// while using its `studio`, which doesn't own it.
    private func screenshots() async -> (ScreenshotsViewModel, AutopilotCenter) {
        let center = StudioTestFixtures.center(StudioDebugHeaderStyle.shotStyle)
        return await (StudioTestFixtures.screenshots(center: center), center)
    }

    @Test func thePicksAreTheTemplatesInTheOrderPicked() async {
        let (model, _) = await screenshots()
        let studio = model.studio
        #expect(studio.shotTemplatePicks == [.cinema, .editorial])
        #expect(studio.shotTemplateNumber(.cinema) == 1)
        #expect(studio.shotTemplateNumber(.editorial) == 2)
        #expect(studio.shotTemplateNumber(.above) == nil)
        #expect(studio.shotTemplatesPickedText == "2 of 3 picked.")
    }

    @Test func pickingAFourthReplacesTheLast() async throws {
        let (model, center) = await screenshots()
        let studio = model.studio
        studio.toggleShotTemplate(.poster)
        #expect(studio.shotTemplatePicks == [.cinema, .editorial, .poster])
        #expect(studio.shotTemplatesPickedText == "3 of 3 picked. Picking another replaces the last.")

        studio.toggleShotTemplate(.band)
        #expect(studio.shotTemplatePicks == [.cinema, .editorial, .band])
        // The plan keeps them by title, as the brief names them.
        let plan = try #require(center.run(for: appID)?.plan)
        #expect(plan.screenshotTemplates == ["Cinema", "Editorial", TemplateStarter.band.title])
    }

    @Test func removingOneRenumbersTheRest() async {
        let (model, _) = await screenshots()
        let studio = model.studio
        studio.toggleShotTemplate(.cinema)
        #expect(studio.shotTemplatePicks == [.editorial])
        #expect(studio.shotTemplateNumber(.editorial) == 1)
        #expect(studio.shotTemplatesPickedText == "1 of 3 picked.")

        studio.toggleShotTemplate(.editorial)
        #expect(studio.shotTemplatePicks.isEmpty)
        #expect(studio.shotTemplatesPickedText == "Pick at least one, up to 3.")
    }

    @Test func thePickerSaysWhoMakesTheDirections() async {
        let (model, _) = await screenshots()
        let note = model.studio.shotTemplatePickerNote
        #expect(note.hasPrefix("From each template you pick, \(model.studio.shotStyleDesigner) makes one screenshot direction"))
        #expect(note.hasSuffix("Each template is previewed with Lumen Journal’s captions and captures."))
    }

    @Test func eachTemplateIsPreviewedOnceLaidOut() async {
        let (model, _) = await screenshots()
        // The set has a template, so the gallery isn't laid out on load.
        let before = model.starterImages(.cinema)
        #expect(before.count == StarterPreview.slotCount)
        #expect(before.allSatisfy { $0 == nil })
        #expect(model.starterFontNote(.cinema).isEmpty)

        await model.renderStarterPreviews()
        model.renderQueue.cancel()
        #expect(model.starterImages(.cinema).count == min(StarterPreview.slotCount, model.document?.slotCount ?? 0))
        #expect(!model.starterFontNote(.cinema).isEmpty)
        #expect(AutopilotShotTemplateCard.slotCount <= StarterPreview.slotCount, "A pick shows the first of the rendered slots")
    }

    @Test func thePickerCountsTheStyleItShows() async {
        let (model, _) = await screenshots()
        #expect(model.galleryCount(in: .bold) == "3 templates · previewed with Lumen’s captions and captures")
        #expect(model.galleryCount(in: nil) == "12 templates · previewed with Lumen’s captions and captures")
    }
}
#endif
