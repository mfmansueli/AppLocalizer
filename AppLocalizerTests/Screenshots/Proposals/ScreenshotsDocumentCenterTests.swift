//
//  ScreenshotsDocumentCenterTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@MainActor
@Suite("ScreenshotsDocumentCenter")
struct ScreenshotsDocumentCenterTests {
    private final class Owner {}

    @Test func watchersAdoptWhatOthersSave() throws {
        let center = ScreenshotsDocumentCenter()
        var owner: Owner? = Owner()
        var received: [ScreenshotsDocument] = []
        try center.observe("1", owner: #require(owner)) { received.append($0) }
        let document = ScreenshotsDebugDocuments.standard
        center.didLoad(document, appID: "1")
        #expect(received.isEmpty)
        var changed = document
        changed.rejectProposal("p1", date: .now)
        center.didSave(changed, appID: "1")
        center.didSave(changed, appID: "1")
        center.didSave(changed, appID: "2")
        #expect(received.count == 1)

        owner = nil
        var again = changed
        again.rejectProposal("p2", date: .now)
        center.didSave(again, appID: "1")
        #expect(received.count == 1)
    }

    @Test func countsWaitingProposalsPerAppFromLoadedDocumentsAndTheDisk() {
        let disk = InMemoryScreenshotsDocumentStore(documents: ["2": ScreenshotsDebugDocuments.standard])
        let center = ScreenshotsDocumentCenter(diskStore: disk)
        center.didLoad(.empty(primary: "en-US"), appID: "1")
        #expect(center.waitingClients(in: ["1", "2", "3"]) == ["2": ["Claude Code", "Claude Code"]])
        var decided = ScreenshotsDebugDocuments.standard
        decided.rejectProposal("p1", date: .now)
        center.didSave(decided, appID: "2")
        #expect(center.waitingClients(in: ["2"]) == ["2": ["Claude Code"]])
    }

    @Test func opensTheSheetOnlyForAppsItCanRead() async {
        let center = ScreenshotsDocumentCenter()
        let services = CenteredScreenshotsServices(document: ScreenshotsDebugDocuments.standard, center: center)
        #expect(!center.canOpenProposals(appID: ScreenshotsTestFixtures.app.id))
        center.openProposals(appID: ScreenshotsTestFixtures.app.id)
        #expect(center.presentedProposals == nil)

        _ = try? await services.loadDocument(for: ScreenshotsTestFixtures.app, primaryLocale: .englishUS)
        #expect(center.canOpenProposals(appID: ScreenshotsTestFixtures.app.id))
        center.openProposals(appID: ScreenshotsTestFixtures.app.id, proposalID: "p2")
        #expect(center.presentedProposals?.selectedID == "p2")
    }

    @Test func theLibraryOpensTheSheetForAppsNobodyLoaded() {
        let center = ScreenshotsDocumentCenter()
        let services = CenteredScreenshotsServices(document: ScreenshotsDebugDocuments.standard, center: center)
        let app = ScreenshotsTestFixtures.app
        center.librarySource = { appID in
            appID == app.id ? ScreenshotsDocumentCenter.Source(app: app, services: services, primaryLocale: .englishUS) : nil
        }
        #expect(center.canOpenProposals(appID: app.id))
        #expect(!center.canOpenProposals(appID: "other"))
        center.openProposals(appID: app.id, proposalID: "p1")
        #expect(center.presentedProposals?.selectedID == "p1")
    }
}
