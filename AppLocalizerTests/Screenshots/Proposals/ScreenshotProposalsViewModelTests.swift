//
//  ScreenshotProposalsViewModelTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("ScreenshotProposalsViewModel")
struct ScreenshotProposalsViewModelTests {
    private let app = ScreenshotsTestFixtures.app

    private func sheet(_ document: ScreenshotsDocument = ScreenshotsDebugDocuments.standard, selecting id: String? = nil) async
        -> (ScreenshotProposalsViewModel, CenteredScreenshotsServices)
    {
        let services = CenteredScreenshotsServices(document: document)
        let model = ScreenshotProposalsViewModel(app: app, services: services, primaryLocale: .englishUS, selecting: id)
        model.now = { ScreenshotsSampleData.today(11, 0) }
        await model.load()
        return (model, services)
    }

    /// The Screenshots view open on the same document as the sheet.
    private func openScreen(_ services: CenteredScreenshotsServices) async -> ScreenshotsViewModel {
        let context = ScreenshotsContext(primaryLocale: .englishUS, version: ScreenshotsTestFixtures.editableVersion)
        let screen = ScreenshotsViewModel(app: app, services: services, context: context)
        await screen.load()
        screen.renderQueue.cancel()
        return screen
    }

    private var staleDocument: ScreenshotsDocument {
        var document = ScreenshotsDebugDocuments.standard
        document.history = ScreenshotsSampleData.staleHistory
        document.proposals.insert(ScreenshotsSampleData.staleProposal, at: 0)
        return document
    }

    @Test func listsTheProposalsWithTheirStatusAndWhatTheyChange() async throws {
        let (model, _) = await sheet(staleDocument)
        #expect(model.proposals.map(\.id) == ["p3", "p1", "p2"])
        #expect(model.selectedID == "p3")
        let cards = model.proposals.map { (model.subtitle(of: $0), model.status(of: $0).title) }
        #expect(cards.map(\.0) == ["Template v3 → v4 · 2 changes", "Template v4 → v5 · 4 changes", "3 captions · German"])
        #expect(cards.map(\.1) == ["Stale", "Waiting", "Waiting"])
        let stale = try #require(model.selected)
        #expect(model.meta(of: stale) == "From Claude Code at Oct 20 · 6:05 PM · based on template v3")
        #expect(model.acceptRefusal(of: stale) == "Rebase it onto v4 first.")
    }

    @Test func acceptingATemplateMakesTheNextVersion() async throws {
        let (model, services) = await sheet(selecting: "p1")
        let proposal = try #require(model.selected)
        #expect(model.acceptRefusal(of: proposal) == nil)
        #expect(model.meta(of: proposal) == "From Claude Code at 10:42 AM · based on template v4")
        let columns = model.stressColumns(for: proposal)
        #expect(columns.map(\.title) == ["English (U.S.) · Primary", "German · Longest", "Arabic · Right to left", "Japanese · CJK"])
        #expect(columns.allSatisfy { $0.after != nil })
        #expect(columns[1].before.fit.fits == false)

        await model.acceptTemplate()
        #expect(services.storedDocument?.history?.currentNumber == 5)
        #expect(try model.status(of: #require(model.selected)) == .accepted)
        #expect(try model.outcome(of: #require(model.selected)) == "Accepted. It’s template v5 now, and the changed renders are waiting in Review & Push.")
    }

    @Test func rejectingATemplateChangesNothing() async throws {
        let (model, services) = await sheet(selecting: "p1")
        await model.reject()
        #expect(services.storedDocument?.history?.currentNumber == 4)
        #expect(model.selected?.status == .rejected)
        #expect(try model.outcome(of: #require(model.selected)) == "Rejected. Nothing changed.")
    }

    @Test func captionsAreAllTickedUntilOneIsUnticked() async throws {
        let (model, services) = await sheet(selecting: "p2")
        let proposal = try #require(model.selected)
        let rows = model.rows(of: proposal)
        #expect(rows.map(\.title) == ["German · slot 2 · Week", "German · slot 3 · Search", "German · slot 5 · Privacy"])
        #expect(rows[1].currentFitText.hasPrefix("Now · 1 line too many"))
        let allFit = rows.allSatisfy(\.proposedFit.fits)
        #expect(allFit)
        #expect(model.acceptSelectedTitle(of: proposal) == "Accept 3 Selected")
        #expect(!model.canAcceptSelected(proposal))

        model.toggle(rows[2].id, in: proposal)
        #expect(model.acceptSelectedTitle(of: proposal) == "Accept 2 Selected")
        #expect(model.canAcceptSelected(proposal))
        await model.acceptCaptions(all: false)

        let document = try #require(services.storedDocument)
        #expect(document.proposal(id: "p2")?.status == .partlyAccepted)
        #expect(document.captions.caption(locale: "de-DE", slot: 2)?.headline == "Einträge aus Jahren in Sekunden finden")
        #expect(document.captions.caption(locale: "de-DE", slot: 4)?.headline == "Privat und nur auf deinen Geräten")
        #expect(try model.outcome(of: #require(model.selected)) == "Partly accepted. Rejected captions stay as they were.")
    }

    @Test func rebasingAStaleProposalWithTheirValue() async throws {
        let (model, services) = await sheet(staleDocument)
        let proposal = try #require(model.selected)
        model.setChoice(.useTheirs, for: "device.width", in: proposal)
        #expect(model.choice(for: "device.width", in: proposal) == .useTheirs)
        await model.rebase()
        let rebased = try #require(services.storedDocument?.proposal(id: "p3"))
        #expect(rebased.basedOnVersion == 4)
        #expect(rebased.template?.operations.map(\.path) == ["safe.top", "device.width"])
        #expect(model.status(of: rebased) == .waiting)
        #expect(model.meta(of: rebased).hasSuffix("based on template v4 · rebased from v3"))
    }

    @Test func aDecisionReachesTheOpenScreenshotsView() async {
        let services = CenteredScreenshotsServices(document: ScreenshotsDebugDocuments.standard)
        let screen = await openScreen(services)
        #expect(screen.matrix.cells.values.contains { $0.proposal != nil })

        let sheet = ScreenshotProposalsViewModel(app: app, services: services, primaryLocale: .englishUS, selecting: "p2")
        await sheet.load()
        await sheet.acceptCaptions(all: true)
        await ScreenshotsTestWaiting.until { screen.document?.proposal(id: "p2")?.status == .accepted }
        #expect(screen.document?.captions.caption(locale: "de-DE", slot: 1)?.headline == "Deine Woche auf einen Blick")
        await ScreenshotsTestWaiting.until { !screen.matrix.cells.values.contains { $0.proposal != nil } }
        #expect(!screen.matrix.cells.values.contains { $0.proposal != nil })
        screen.renderQueue.cancel()
    }

    @Test func acceptedCaptionsReadProposedByTheAssistantUntilEdited() async throws {
        let services = CenteredScreenshotsServices(document: ScreenshotsDebugDocuments.standard)
        let screen = await openScreen(services)
        let sheet = ScreenshotProposalsViewModel(app: app, services: services, primaryLocale: .englishUS, selecting: "p2")
        await sheet.load()
        await sheet.acceptCaptions(all: true)
        await ScreenshotsTestWaiting.until { screen.document?.proposal(id: "p2")?.status == .accepted }

        let key = LocaleSlot(locale: "de-DE", slot: 1)
        let accepted = try #require(screen.document?.captions.caption(locale: key.locale, slot: key.slot))
        #expect(accepted.provenance.title.hasPrefix("Proposed by Claude Code · "))

        screen.captions.select(key)
        screen.captions.setHeadline("Deine Woche im Blick")
        await screen.captions.commitEdits()
        let edited = try #require(screen.document?.captions.caption(locale: key.locale, slot: key.slot))
        #expect(edited.provenance == .edited)
        screen.renderQueue.cancel()
    }
}
