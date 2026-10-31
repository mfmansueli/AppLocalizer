//
//  SuggestionRunAcceptanceTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Accept All on Suggest Everything's card: the values go into the queue
/// as the pages would put them, tagged with who suggested them, and Undo
/// puts the queue and the decisions back.
@MainActor
@Suite("SuggestionRunAcceptance")
struct SuggestionRunAcceptanceTests {
    private let changes = ChangeQueue()
    private let store = FieldSuggestionStore()
    private let storeApp = StorePageContentFixtures.app
    private let lumen = StoreApp(id: DebugFixtures.AppID.lumen, name: "Lumen Information", bundleID: "dev.example.info", sku: nil, primaryLocale: "en-US")
    private let claude = SuggestionSource.assistant(client: "Claude Code")

    private var workspace: MCPWorkspace {
        MCPTestFixtures.workspace(
            apps: [storeApp, lumen],
            changes: changes,
            storePage: FakeStorePageServices(),
            appInformation: DebugAppInformationServices()
        )
    }

    private func add(_ target: SuggestionTarget, _ value: String, app: StoreApp.ID) -> FieldSuggestion {
        store.add(appID: app, target: target, value: value, reason: "", source: claude).suggestion
    }

    @Test func storePageValuesGoInTaggedAndUndoTakesThemBack() async throws {
        let batch = [
            add(.storePage(.englishUS, .subtitle), "Private diary, mood & prompts", app: storeApp.id),
            add(.storePage(.german, .whatsNew), "Wochenrückblick", app: storeApp.id),
        ]
        let accepted = await SuggestionRunAcceptance.accept(batch, appID: storeApp.id, in: workspace, store: store)
        #expect(accepted.count == 2)
        #expect(store.open(for: storeApp.id).isEmpty)
        #expect(store.provenance(for: .storePage(.englishUS, .subtitle), appID: storeApp.id)?.source == claude)

        let draft = try await MCPListingDraft.load(app: storeApp.id, in: workspace)
        #expect(draft.listing.value(.subtitle, in: .englishUS) == "Private diary, mood & prompts")
        #expect(draft.listing.value(.whatsNew, in: .german) == "Wochenrückblick")
        #expect(changes.changes(for: storeApp.id).allSatisfy { $0.source == .assistant(client: "Claude Code") })

        SuggestionRunAcceptance.undo(accepted.undo, queue: changes, store: store)
        #expect(changes.changes(for: storeApp.id).isEmpty)
        #expect(store.open(for: storeApp.id).count == 2)
    }

    @Test func appInformationAnswersGoInAndUndoTakesThemBack() async throws {
        let batch = [
            add(.appInformation(.secondaryCategory), "PRODUCTIVITY", app: lumen.id),
            add(AppInformationSuggestionSlot.ageRating(.wellness).target, AgeRatingAnswer.affirmative.rawValue, app: lumen.id),
            add(AppInformationSuggestionSlot.accessibility(.iPhone, .reducedMotion).target, AppInformationSuggestionSlot.supported, app: lumen.id),
        ]
        let accepted = await SuggestionRunAcceptance.accept(batch, appID: lumen.id, in: workspace, store: store)
        #expect(accepted.count == 3)
        #expect(store.open(for: lumen.id).isEmpty)

        let draft = try await MCPAppInformationDraft.load(app: lumen.id, in: workspace)
        #expect(draft.value(.secondaryCategory) == "PRODUCTIVITY")
        #expect(draft.slots.value(.ageRating(.wellness)) == AgeRatingAnswer.affirmative.rawValue)
        #expect(draft.slots.value(.accessibility(.iPhone, .reducedMotion)) == AppInformationSuggestionSlot.supported)

        SuggestionRunAcceptance.undo(accepted.undo, queue: changes, store: store)
        #expect(changes.changes(for: lumen.id).isEmpty)
        #expect(store.open(for: lumen.id).count == 3)
    }

    @Test func theRunsAcceptAllTakesWhatsStillOpen() throws {
        let run = store.startRun(appID: storeApp.id, client: "Claude Code", plan: [.storePage(.englishUS, .subtitle), .storePage(.german, .whatsNew)])
        let first = store.add(appID: storeApp.id, target: .storePage(.englishUS, .subtitle), value: "A", reason: "", source: claude, runID: run.id)
        store.add(appID: storeApp.id, target: .storePage(.german, .whatsNew), value: "B", reason: "", source: claude, runID: run.id)
        store.dismiss([first.suggestion.id])
        let current = try #require(store.run)
        #expect(store.toReview(in: current).map(\.value) == ["B"])
    }
}
#endif
