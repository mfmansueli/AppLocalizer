//
//  ScreenshotsDocumentCenter.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Keeps everything that shows an app's screenshot document in step. The
/// Screenshots view, the Proposals sheet and the assistant tools each load
/// and save through `ScreenshotsServices`, which report here; whoever else
/// watches that app adopts the saved document, so a proposal an assistant
/// sends shows up in the open view, and one accepted in the sheet updates
/// the Sets matrix.
///
/// It also answers the toolbar's assistant indicator, which counts the
/// screenshot proposals waiting per app, and holds the Proposals sheet the
/// indicator presents.
@MainActor
@Observable
final class ScreenshotsDocumentCenter {
    /// The one live services report to (and DEBUG scenes', one scene per
    /// process). Tests make their own.
    static let shared = ScreenshotsDocumentCenter(diskStore: FileScreenshotsDocumentStore())

    /// Each app's document as last loaded or saved this launch.
    private(set) var documents: [StoreApp.ID: ScreenshotsDocument] = [:]

    /// The Proposals sheet the toolbar presents; nil when it's closed.
    var presentedProposals: ScreenshotProposalsViewModel?

    /// Where documents nobody loaded yet are read from, so proposals saved
    /// in an earlier launch still count in the toolbar. Nil reads nothing
    /// (DEBUG scenes, tests).
    @ObservationIgnored var diskStore: (any ScreenshotsDocumentStore)?
    @ObservationIgnored private var probed: [StoreApp.ID: ScreenshotsDocument?] = [:]
    @ObservationIgnored private var observers: [UUID: Observer] = [:]
    /// What opens each app's Proposals sheet, from whoever loaded its
    /// document this launch.
    private(set) var sources: [StoreApp.ID: Source] = [:]
    /// What opens the sheet for an app nobody loaded yet: the main window
    /// looks the app up in its library.
    @ObservationIgnored var librarySource: (@MainActor (StoreApp.ID) -> Source?)?

    /// An app and the services that read its document.
    struct Source {
        var app: StoreApp
        var services: any ScreenshotsServices
        var primaryLocale: StoreLocale
    }

    private struct Observer {
        var appID: StoreApp.ID
        weak var owner: AnyObject?
        var handler: @MainActor (ScreenshotsDocument) -> Void
    }

    init(diskStore: (any ScreenshotsDocumentStore)? = nil) {
        self.diskStore = diskStore
    }

    // MARK: - Reports from services

    /// A services object read `document`. Nobody is told: it's what they
    /// already have.
    func didLoad(_ document: ScreenshotsDocument, appID: StoreApp.ID) {
        if documents[appID] != document { documents[appID] = document }
    }

    /// Remembers how to open `app`'s Proposals sheet.
    func register(_ app: StoreApp, services: any ScreenshotsServices, primaryLocale: StoreLocale) {
        if sources[app.id] == nil { sources[app.id] = Source(app: app, services: services, primaryLocale: primaryLocale) }
    }

    // MARK: - The Proposals sheet

    /// Whether `appID`'s Proposals sheet can open: its document was read
    /// this launch, or the app is in the library.
    func canOpenProposals(appID: StoreApp.ID) -> Bool {
        source(for: appID) != nil
    }

    /// Opens the Proposals sheet for `appID`, on `proposalID` or the first
    /// waiting proposal.
    func openProposals(appID: StoreApp.ID, proposalID: String? = nil) {
        guard let source = source(for: appID) else { return }
        presentedProposals = ScreenshotProposalsViewModel(
            app: source.app, services: source.services, primaryLocale: source.primaryLocale, selecting: proposalID
        )
    }

    private func source(for appID: StoreApp.ID) -> Source? {
        sources[appID] ?? librarySource?(appID)
    }

    /// A services object saved `document`: every watcher of the app adopts
    /// it, unless it's what they already have.
    func didSave(_ document: ScreenshotsDocument, appID: StoreApp.ID) {
        guard documents[appID] != document else { return }
        documents[appID] = document
        for (id, observer) in observers where observer.appID == appID {
            guard observer.owner != nil else {
                observers[id] = nil
                continue
            }
            observer.handler(document)
        }
    }

    // MARK: - Watching

    /// Calls `handler` with every document saved for `appID` while `owner`
    /// lives.
    func observe(_ appID: StoreApp.ID, owner: AnyObject, handler: @escaping @MainActor (ScreenshotsDocument) -> Void) {
        observers[UUID()] = Observer(appID: appID, owner: owner, handler: handler)
    }

    // MARK: - Waiting proposals

    /// The app's proposals nobody decided yet.
    func waitingProposals(appID: StoreApp.ID) -> [ScreenshotProposal] {
        document(appID: appID)?.waitingProposals ?? []
    }

    /// For each app in `library` with screenshot proposals waiting, the
    /// assistant of each one.
    func waitingClients(in library: [StoreApp.ID]) -> [StoreApp.ID: [String]] {
        var clients: [StoreApp.ID: [String]] = [:]
        for appID in library {
            let waiting = waitingProposals(appID: appID)
            if !waiting.isEmpty { clients[appID] = waiting.map(\.client) }
        }
        return clients
    }

    /// The loaded document, else the one on disk, read once.
    private func document(appID: StoreApp.ID) -> ScreenshotsDocument? {
        if let document = documents[appID] { return document }
        if let probe = probed[appID] { return probe }
        let document = (try? diskStore?.load(appID: appID)) ?? nil
        probed[appID] = document
        return document
    }
}
