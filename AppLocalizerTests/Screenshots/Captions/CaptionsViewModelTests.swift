//
//  CaptionsViewModelTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The Captions tab: the table's rows, states and counts, and the editor's
/// live fit, provenance, Mark Reviewed and shorter versions.
@MainActor
@Suite("CaptionsViewModel")
struct CaptionsViewModelTests {
    private let german = LocaleSlot(locale: "de-DE", slot: 2)

    /// The Screenshots view model and its fakes; the Captions tab is
    /// reached through the view model, which owns it.
    @MainActor
    struct Screen {
        let model: ScreenshotsViewModel
        let services: FakeScreenshotsServices

        var captions: CaptionsViewModel { model.captions }
    }

    private func makeScreen(_ document: ScreenshotsDocument = ScreenshotsDebugDocuments.standard) async -> Screen {
        let (model, services) = await ScreenshotsTestFixtures.viewModel(document)
        return Screen(model: model, services: services)
    }

    // MARK: - The table

    @Test func theTableIsThePrimaryThenTheLocalesByName() async {
        let screen = await makeScreen()
        let rows = screen.captions.allRows
        #expect(rows.count == 12)
        #expect(rows.first?.locale.code == "en-US")
        #expect(rows.first?.isPrimary == true)
        #expect(rows.dropFirst().first?.locale.code == "ar-SA")
        #expect(rows.allSatisfy { $0.cells.count == 5 })
        #expect(screen.captions.notLocalizedCount == 27)
        #expect(screen.captions.slotHeader(0) == (name: "Today", hasSubhead: true))
        #expect(screen.captions.slotHeader(2).hasSubhead == false)
    }

    @Test func theCountsAreTheDesigns() async {
        let screen = await makeScreen()
        #expect(screen.captions.stats == "12 locales × 5 slots · 1 overflow · 9 machine-translated · 0 missing")
    }

    @Test func cellsShowTheirStates() async throws {
        let screen = await makeScreen()
        let cells = screen.captions.allRows.flatMap(\.cells)
        let overflowing = try #require(cells.first { $0.key == german })
        #expect(overflowing.isOverflowing)
        #expect(overflowing.isEdited)
        #expect(overflowing.fitLabel == "1 line too many at 80 u")
        #expect(overflowing.needsAttention)
        let machine = try #require(cells.first { $0.key == LocaleSlot(locale: "zh-Hans", slot: 1) })
        #expect(machine.isMachineTranslated)
        let primary = try #require(cells.first { $0.key == LocaleSlot(locale: "en-US", slot: 0) })
        #expect(!primary.isEdited)
        #expect(primary.showsSubhead)
        #expect(primary.accessibilityText(localeName: "English (U.S.)").hasPrefix("English (U.S.) slot 1: Write a little every day"))
    }

    @Test func aProposalTagsItsCellWithTheAssistant() async throws {
        let screen = await makeScreen()
        let proposal = try #require(screen.model.document?.proposals.first { !$0.captionSlots.isEmpty })
        let (locale, slots) = try #require(proposal.captionSlots.first)
        let slot = try #require(slots.first)
        let cell = screen.captions.allRows.flatMap(\.cells).first { $0.key == LocaleSlot(locale: locale, slot: slot) }
        #expect(cell?.assistant == proposal.client)
    }

    @Test func missingCaptionsSayWhatToDo() async {
        var document = ScreenshotsDebugDocuments.standard
        document.captions.setCaption(nil, locale: "en-US", slot: 4)
        document.captions.setCaption(nil, locale: "fr-FR", slot: 4)
        let screen = await makeScreen(document)
        let cells = screen.captions.allRows.flatMap(\.cells)
        #expect(cells.first { $0.key == LocaleSlot(locale: "en-US", slot: 4) }?.missingTitle == "Write caption")
        #expect(cells.first { $0.key == LocaleSlot(locale: "fr-FR", slot: 4) }?.missingTitle == "Missing")
        #expect(screen.captions.stats.hasSuffix("· 2 missing"))
    }

    @Test func needsAttentionShowsOnlyRowsWithAProblem() async {
        let screen = await makeScreen()
        screen.captions.filter = .needsAttention
        let codes = screen.captions.rows.map(\.locale.code)
        #expect(codes.contains("de-DE"))
        #expect(codes.contains("zh-Hans"))
        #expect(!codes.contains("fr-FR"))
        let allNeedAttention = screen.captions.rows.allSatisfy(\.needsAttention)
        #expect(allNeedAttention)
    }

    // MARK: - The editor

    @Test func selectingACaptionFillsTheEditor() async throws {
        let screen = await makeScreen()
        screen.model.editCaption(at: german)
        #expect(screen.model.tab == .captions)
        #expect(screen.captions.selection == german)
        #expect(screen.captions.editorTitle == "German · slot 3")
        #expect(screen.captions.editorSubtitle == "Search · iPhone 6.9″")
        #expect(screen.captions.sourceHeadline == "Search years of entries in seconds")
        #expect(screen.captions.headline.hasPrefix("Durchsuche"))
        #expect(!screen.captions.showsSubheadField)
        let fit = try #require(screen.captions.editorPreview?.fit)
        #expect(fit.tone == .overflows)
        #expect(screen.captions.fitDetail == "3 lines of 2 · 80 u (template 112, smallest 80)")
        #expect(screen.captions.canSuggestShorter)
    }

    @Test func theFitFollowsEveryKeystroke() async throws {
        let screen = await makeScreen()
        screen.captions.select(german)
        let saves = screen.services.saved.count
        screen.captions.setHeadline("Einträge in Sekunden finden")
        #expect(screen.captions.hasPendingEdit)
        #expect(screen.captions.editorPreview?.fit.tone == .fits)
        #expect(screen.services.saved.count == saves)
        #expect(!screen.captions.canSuggestShorter)

        await screen.captions.commitEdits()
        let saved = try #require(screen.services.storedDocument?.captions.caption(locale: "de-DE", slot: 2))
        #expect(saved.headline == "Einträge in Sekunden finden")
        #expect(saved.provenance == .edited)
        #expect(!screen.captions.hasPendingEdit)
        #expect(screen.captions.allRows.flatMap(\.cells).first { $0.key == german }?.isOverflowing == false)
    }

    @Test func typingStopsThenTheCaptionIsWritten() async {
        let screen = await makeScreen()
        screen.captions.select(german)
        screen.captions.setHeadline("Einträge finden")
        let written = await ScreenshotsTestWaiting.until {
            screen.services.storedDocument?.captions.caption(locale: "de-DE", slot: 2)?.headline == "Einträge finden"
        }
        #expect(written)
    }

    @Test func movingOnWritesTheEditFirst() async {
        let screen = await makeScreen()
        screen.captions.select(german)
        screen.captions.setHeadline("Einträge finden")
        screen.captions.select(LocaleSlot(locale: "fr-FR", slot: 0))
        #expect(screen.captions.headline.hasPrefix("Écrivez"))
        let written = await ScreenshotsTestWaiting.until {
            screen.services.storedDocument?.captions.caption(locale: "de-DE", slot: 2)?.headline == "Einträge finden"
        }
        #expect(written)
    }

    @Test func thePrimaryCaptionIsWrittenAndAnEmptyHeadlineRemovesIt() async {
        let screen = await makeScreen()
        screen.captions.select(LocaleSlot(locale: "en-US", slot: 0))
        #expect(screen.captions.showsSubheadField)
        #expect(screen.captions.sourceHeadline == nil)
        screen.captions.setSubhead("Prompts for every mood")
        await screen.captions.commitEdits()
        #expect(screen.services.storedDocument?.captions.caption(locale: "en-US", slot: 0)?.provenance == .written)
        #expect(screen.services.storedDocument?.captions.caption(locale: "en-US", slot: 0)?.subhead == "Prompts for every mood")

        screen.captions.select(LocaleSlot(locale: "fr-FR", slot: 1))
        screen.captions.setHeadline("  ")
        await screen.captions.commitEdits()
        #expect(screen.services.storedDocument?.captions.caption(locale: "fr-FR", slot: 1) == nil)
    }

    @Test func markReviewedDropsTheMachineTag() async {
        let screen = await makeScreen()
        let key = LocaleSlot(locale: "zh-Hans", slot: 1)
        screen.captions.select(key)
        #expect(screen.captions.isMachineTranslated)
        await screen.captions.markReviewed()
        #expect(screen.services.storedDocument?.captions.caption(locale: key.locale, slot: key.slot)?.provenance == .reviewed)
        #expect(!screen.captions.isMachineTranslated)
    }

    @Test func aShorterVersionIsOfferedAndUsedAsMachineTranslated() async throws {
        let screen = await makeScreen()
        screen.services.translator = CannedCaptionTranslator(answers: ["de-DE": "Einträge aus Jahren in Sekunden finden"])
        screen.captions.select(german)
        await screen.captions.suggestShorter()
        let suggestion = try #require(screen.captions.suggestion)
        #expect(suggestion.headline == "Einträge aus Jahren in Sekunden finden")
        #expect(suggestion.providerTitle == "Apple Translation")
        #expect(suggestion.fit.fill < (screen.captions.editorPreview?.fit.fill ?? 0))
        #expect(!screen.captions.canSuggestShorter)

        await screen.captions.useSuggestion()
        let saved = screen.services.storedDocument?.captions.caption(locale: "de-DE", slot: 2)
        #expect(saved?.headline == "Einträge aus Jahren in Sekunden finden")
        #expect(saved?.provenance == .machineTranslated)
        #expect(screen.captions.suggestion == nil)
        #expect(screen.captions.headline == "Einträge aus Jahren in Sekunden finden")
    }

    @Test func aSuggestionThatIsntShorterIsntOffered() async {
        let screen = await makeScreen()
        screen.services.translator = CannedCaptionTranslator(overlong: ["de-DE"])
        screen.captions.select(german)
        await screen.captions.suggestShorter()
        #expect(screen.captions.suggestion == nil)
        #expect(screen.captions.suggestionMessage == "Apple Translation’s version isn’t any shorter.")
    }

    @Test func keepMineDropsTheSuggestion() async {
        let screen = await makeScreen()
        screen.services.translator = CannedCaptionTranslator(answers: ["de-DE": "Schnell finden"])
        screen.captions.select(german)
        await screen.captions.suggestShorter()
        #expect(screen.captions.suggestion != nil)
        screen.captions.keepMine()
        #expect(screen.captions.suggestion == nil)
        #expect(screen.services.storedDocument?.captions.caption(locale: "de-DE", slot: 2)?.headline.hasPrefix("Durchsuche") == true)
    }

    @Test func aLanguageNotDownloadedSaysSo() async {
        let screen = await makeScreen()
        screen.services.translator = CannedCaptionTranslator(availability: ["de-DE": .needsDownload])
        screen.captions.select(german)
        await screen.captions.suggestShorter()
        #expect(screen.captions.suggestion == nil)
        #expect(screen.captions.suggestionMessage?.hasPrefix("Apple Translation needs German downloaded first.") == true)
    }

    @Test func closingTheEditorWritesTheEdit() async {
        let screen = await makeScreen()
        screen.captions.select(german)
        screen.captions.setHeadline("Finden")
        screen.captions.close()
        #expect(screen.captions.selection == nil)
        let written = await ScreenshotsTestWaiting.until {
            screen.services.storedDocument?.captions.caption(locale: "de-DE", slot: 2)?.headline == "Finden"
        }
        #expect(written)
    }
}
#endif
