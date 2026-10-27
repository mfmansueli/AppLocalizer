//
//  CaptionTranslationTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Translate Missing… on the Captions tab, with a canned translator: the
/// plan, each arrival written tagged machine-translated and measured, the
/// glossary kept, and what happens when a language isn't downloaded.
@MainActor
@Suite("CaptionTranslation")
struct CaptionTranslationTests {
    private static let added = ["fi", "pl", "sv", "tr"]

    /// The standard document with Finnish, Polish, Swedish and Turkish in
    /// scope and no captions for them.
    /// The Screenshots view model and its fakes; the translation is
    /// reached through the view model, which owns it.
    @MainActor
    struct Screen {
        let model: ScreenshotsViewModel
        let services: FakeScreenshotsServices

        var translation: CaptionTranslationViewModel { model.captions.translation }
    }

    private func makeScreen(_ translator: any ListingTranslator = CannedCaptionTranslator()) async -> Screen {
        var document = ScreenshotsDebugDocuments.standard
        document.scope.setLocalized(ScreenshotsSampleData.scope + Self.added)
        let (model, services) = await ScreenshotsTestFixtures.viewModel(document)
        services.translator = translator
        model.captions.translation.prepare(provider: .appleTranslation, glossary: TranslationGlossary())
        return Screen(model: model, services: services)
    }

    // MARK: - The plan

    @Test func thePlanIsEveryEmptyCaptionInScope() async {
        let screen = await makeScreen()
        let plan = screen.translation.plan
        #expect(plan.totalCount == 20)
        #expect(plan.summary == "20 empty captions in 4 locales.")
        #expect(plan.locales.map(\.code) == Self.added)
        #expect(plan.itemCount(in: StoreLocaleCatalog.locale(code: "pl") ?? .englishUS) == 5)
        #expect(screen.translation.startTitle == "Translate 20")
        #expect(screen.translation.canStart)
    }

    @Test func uncheckingALocaleLeavesItOut() async throws {
        let screen = await makeScreen()
        let turkish = try #require(StoreLocaleCatalog.locale(code: "tr"))
        screen.translation.setIncluded(turkish, false)
        #expect(!screen.translation.isIncluded(turkish))
        #expect(screen.translation.selectedPlan.totalCount == 15)
        #expect(screen.translation.startTitle == "Translate 15")
    }

    @Test func aLocaleInThePrimarysLanguageGetsACopy() {
        var captions = CaptionBook()
        captions.setCaption(ScreenshotCaption(headline: "Write a little every day"), locale: "en-US", slot: 0)
        let locales = ["en-US", "en-GB", "fr-FR"].compactMap(StoreLocaleCatalog.locale(code:))
        let plan = CaptionTranslationPlanner.plan(captions: captions, locales: locales, primary: .englishUS, slotCount: 2)
        #expect(plan.items.map(\.key.locale) == ["en-GB", "fr-FR"])
        #expect(plan.items.map(\.method) == [.copy, .translate])
        #expect(plan.items.first?.title == "English (U.K.) · slot 1")
    }

    @Test func providersThatNeedSetupCantStart() async {
        let screen = await makeScreen()
        screen.translation.provider = .aiProvider
        #expect(!screen.translation.canStart)
        #expect(TranslationProvider.aiProvider.captionTitle(vendor: .anthropic) == "AI provider · Anthropic")
        #expect(TranslationProvider.appleTranslation.captionDetail == "Free and private. Translates the caption as written.")
    }

    @Test func theAIProviderStartsOnceItsKeyIsSaved() async {
        let screen = await makeScreen()
        let setup = AIProviderSetup(vendor: .openAI, hasKey: true) { _ in CannedCaptionTranslator() }
        screen.translation.prepare(provider: .aiProvider, glossary: TranslationGlossary(), aiProvider: setup)
        #expect(screen.translation.setupMessage == nil)
        #expect(screen.translation.canStart)
    }

    // MARK: - Running

    @Test func theAIProviderSkipsAppleTranslationsDownloads() async {
        let screen = await makeScreen(CannedCaptionTranslator(availability: ["pl": .needsDownload]))
        let setup = AIProviderSetup(vendor: .anthropic, hasKey: true) { _ in CannedCaptionTranslator() }
        screen.translation.prepare(provider: .aiProvider, glossary: TranslationGlossary(), aiProvider: setup)
        screen.translation.start()
        await screen.translation.waitUntilFinished()
        #expect(screen.services.storedDocument?.captions.caption(locale: "pl", slot: 0)?.headline.hasPrefix("[pl] ") == true)
        #expect(screen.translation.job?.failedCount == 0)
    }

    @Test func eachArrivalIsWrittenTaggedMachineTranslated() async throws {
        let screen = await makeScreen()
        screen.translation.start()
        #expect(screen.translation.isRunning)
        await screen.translation.waitUntilFinished()
        #expect(!screen.translation.isRunning)
        for locale in Self.added {
            for slot in 0..<5 {
                let caption = try #require(screen.services.storedDocument?.captions.caption(locale: locale, slot: slot))
                #expect(caption.provenance == .machineTranslated)
                #expect(caption.headline.hasPrefix("[\(locale)] "))
            }
        }
        let subhead = screen.services.storedDocument?.captions.caption(locale: "fi", slot: 0)?.subhead
        #expect(subhead == "[fi] Gentle prompts that fit your mood")
        #expect(screen.model.notice == "Translated 20 captions with Apple Translation.")
        #expect(screen.translation.flagged.isEmpty)
    }

    @Test func theGlossaryTermsAreNeverSentForTranslation() async throws {
        let translator = CannedCaptionTranslator()
        var document = ScreenshotsDebugDocuments.standard
        document.scope.setLocalized(ScreenshotsSampleData.scope + ["fi"])
        document.captions.setCaption(ScreenshotCaption(headline: "Lumen keeps your week calm"), locale: "en-US", slot: 1)
        let (model, services) = await ScreenshotsTestFixtures.viewModel(document)
        services.translator = translator
        let screen = Screen(model: model, services: services)
        screen.translation.prepare(provider: .appleTranslation, glossary: TranslationGlossary(terms: ["Lumen"]))
        screen.translation.start()
        await screen.translation.waitUntilFinished()
        #expect(!translator.sent.texts.contains { $0.contains("Lumen") })
        let caption = try #require(screen.services.storedDocument?.captions.caption(locale: "fi", slot: 1))
        #expect(caption.headline.contains("Lumen"))
    }

    @Test func captionsThatDontFitAreFlaggedNeverCut() async {
        let screen = await makeScreen(CannedCaptionTranslator(overlong: ["tr"]))
        screen.translation.start()
        await screen.translation.waitUntilFinished()
        #expect(screen.translation.flagged.count == 5)
        #expect(screen.translation.flagged.allSatisfy { $0.locale == "tr" })
        #expect(screen.services.storedDocument?.captions.caption(locale: "tr", slot: 2)?.headline == CannedCaptionTranslator.overlongText)
        #expect(screen.model.notice == "Translated 20 captions with Apple Translation. 5 don’t fit and are flagged.")
        #expect(screen.model.captions.allRows.flatMap(\.cells).first { $0.key == LocaleSlot(locale: "tr", slot: 2) }?.isOverflowing == true)
    }

    @Test func aLanguageThatIsntDownloadedFailsAndSaysWhy() async throws {
        let screen = await makeScreen(CannedCaptionTranslator(availability: ["pl": .needsDownload]))
        await screen.translation.checkAvailability()
        #expect(screen.translation.localesNeedingDownload.map(\.code) == ["pl"])
        screen.translation.start()
        await screen.translation.waitUntilFinished()
        #expect(screen.services.storedDocument?.captions.caption(locale: "pl", slot: 0) == nil)
        #expect(screen.services.storedDocument?.captions.caption(locale: "sv", slot: 0) != nil)
        let notice = try #require(screen.model.notice)
        #expect(notice.hasPrefix("Translated 15 captions with Apple Translation. 5 couldn’t be translated:"))
    }

    @Test func cancelKeepsWhatArrived() async throws {
        let held = DebugCaptionTranslator(delay: .zero, holdsAt: LocaleSlot(locale: "pl", slot: 2))
        let screen = await makeScreen(held)
        screen.translation.start()
        let reached = await ScreenshotsTestWaiting.until { screen.translation.job?.current?.key == LocaleSlot(locale: "pl", slot: 2) }
        #expect(reached)
        #expect(screen.translation.job?.progressLine == "7 of 20 · Polish · slot 3")
        screen.translation.cancel()
        #expect(!screen.translation.isRunning)
        let book = try #require(screen.services.storedDocument?.captions)
        #expect(book.caption(locale: "pl", slot: 1)?.headline.isEmpty == false)
        #expect(book.caption(locale: "pl", slot: 2) == nil)
        #expect(book.caption(locale: "tr", slot: 0) == nil)
    }

    @Test func theAssistantPromptNamesTheAppTheTermsAndTheTone() {
        let glossary = TranslationGlossary(terms: ["Lumen", "Face ID"])
        let prompt = CaptionAssistantPrompt(appName: "Lumen Journal", versionString: "1.4", glossary: glossary)
        #expect(prompt.slashCommand == "/mcp__applocalizer__translate_captions Lumen Journal")
        #expect(prompt.text.hasPrefix("Use AppLocalizer to translate the empty screenshot captions for Lumen Journal 1.4."))
        #expect(prompt.text.contains("Keep “Lumen” and “Face ID” untranslated"))
    }
}
#endif
