//
//  ScreenshotsLanguagePageTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The Screenshots language page on Lumen Journal's sample document, where
/// Claude Code suggested three shorter German captions: the language bar,
/// Accept and Dismiss per caption, Accept here, Accept All Languages, and
/// Undo.
@MainActor
@Suite("Screenshots language page")
struct ScreenshotsLanguagePageTests {
    private func german() async -> (ScreenshotsViewModel, FakeScreenshotsServices) {
        let (model, services) = await ScreenshotsTestFixtures.viewModel()
        model.pageLocale = .german
        return (model, services)
    }

    private func savedHeadline(_ services: FakeScreenshotsServices, slot: Int) -> String? {
        services.storedDocument?.captions.caption(locale: "de-DE", slot: slot)?.headline
    }

    @Test func theLanguageBarCountsTheSuggestedCaptions() async {
        let (model, _) = await german()
        #expect(model.pageLocales.first == .englishUS)
        #expect(model.currentPageLocale == .german)
        let bar = model.languageBarModel(acceptsRightAway: false)
        #expect(bar.hereText == "3 suggestions here")
        #expect(bar.totalCount == 3)
        #expect(model.pageStatus(of: StoreLocale.german) == "3 captions suggested")
        #expect(model.proposedCaption(locale: "de-DE", slot: 1)?.item.headline == "Deine Woche auf einen Blick")
        #expect(model.proposedCaption(locale: "de-DE", slot: 0) == nil)
    }

    @Test func aLanguageNotInTheSetFallsBackToThePrimary() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        model.pageLocale = StoreLocale("xx-XX", "Nowhere", region: "XX", language: "xx")
        #expect(model.currentPageLocale == model.pageLocales.first)
    }

    @Test func acceptingOneCaptionSavesItAndUndoBringsItBack() async throws {
        let (model, services) = await german()
        let caption = try #require(model.proposedCaption(locale: "de-DE", slot: 1))
        await model.acceptCaption(caption)
        #expect(model.captionToast?.text == "Screenshot 2 caption accepted. It’s in Review & Push.")
        #expect(model.captionToast?.actionTitle == "Review & Push")
        #expect(savedHeadline(services, slot: 1) == "Deine Woche auf einen Blick")
        #expect(model.proposedCaptions.count == 2)

        await model.undoCaptionToast()
        #expect(model.captionToast == nil)
        #expect(model.proposedCaptions.count == 3)
        #expect(savedHeadline(services, slot: 1) != "Deine Woche auf einen Blick")
    }

    @Test func dismissingOffersNoReview() async throws {
        let (model, services) = await german()
        let caption = try #require(model.proposedCaption(locale: "de-DE", slot: 2))
        let before = savedHeadline(services, slot: 2)
        await model.dismissCaption(caption)
        #expect(model.captionToast?.text == "Screenshot 3 caption dismissed.")
        #expect(model.captionToast?.actionTitle == nil)
        #expect(model.proposedCaption(locale: "de-DE", slot: 2) == nil)
        #expect(savedHeadline(services, slot: 2) == before)
    }

    @Test func acceptHereTakesTheLanguageInView() async {
        let (model, _) = await german()
        await model.acceptCaptionsHere()
        #expect(model.captionToast?.text == "Accepted 3 captions in German. They’re in Review & Push.")
        #expect(model.proposedCaptions.isEmpty)
    }

    @Test func acceptAllAsksFirstUnlessToldNotTo() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        await model.acceptAllCaptions(withoutAsking: false)
        #expect(model.isAcceptAllCaptionsPresented)
        let selection = model.acceptAllCaptionsSelection()
        #expect(selection.kind == .screenshots)
        #expect(selection.groups.map(\.id) == ["de-DE"])
        #expect(selection.focusedGroupID == "de-DE")
        #expect(selection.groups.first?.items.first?.suggested == "Deine Woche auf einen Blick")

        await model.acceptAllCaptions(withoutAsking: true)
        #expect(model.captionToast?.text == "Accepted 3 suggestions in 1 language, without asking. They’re in Review & Push.")
        #expect(model.proposedCaptions.isEmpty)
    }

    @Test func theSheetAcceptsOnlyWhatStayedTicked() async throws {
        let (model, _) = await german()
        model.isAcceptAllCaptionsPresented = true
        let first = try #require(model.proposedCaptions.first)
        await model.acceptCaptions(ids: [first.id], turnedOffAsking: true)
        #expect(!model.isAcceptAllCaptionsPresented)
        #expect(model.captionToast?.text
            == "Accepted 1 suggestion in 1 language. They’re in Review & Push. Next time, Accept All Languages won’t ask first.")
        #expect(model.proposedCaptions.count == 2)
    }

    @Test func useAndEditOpensTheCaptionInCaptions() async throws {
        let (model, _) = await german()
        model.showsLanguagePage = true
        let caption = try #require(model.proposedCaption(locale: "de-DE", slot: 4))
        await model.useAndEditCaption(caption)
        #expect(model.tab == .captions)
        #expect(!model.showsLanguagePage)
        #expect(model.captions.selection == caption.key)
        #expect(model.captionToast == nil)
    }
}
#endif
