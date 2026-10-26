//
//  StorePageMachineTranslationTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// "Machine-translated, not reviewed": kept on this Mac per app, version
/// and field, cleared by any edit or Mark Reviewed.
@MainActor
@Suite("Store Page machine-translation tags")
struct StorePageMachineTranslationTests {
    private let app = StorePageContentFixtures.app
    private let versionScope = MachineTranslationScope.version("v2")
    private let descriptionKey = ListingFieldKey(.german, .description)

    /// A store where the German description, as App Store Connect has it,
    /// was accepted machine translation.
    private func taggedStore() -> InMemoryMachineTranslationStore {
        let store = InMemoryMachineTranslationStore()
        store.setTags([descriptionKey.id: StorePageFixtures.germanTexts[.description] ?? ""], appID: app.id, scope: versionScope)
        return store
    }

    private func makeModel(
        store: InMemoryMachineTranslationStore,
        queue: ChangeQueue = ChangeQueue(),
        summaries: AppSummaryStore? = nil
    ) async -> StorePageViewModel {
        let model = StorePageViewModel(app: app, services: FakeStorePageServices(machineTranslations: store), queue: queue, summaries: summaries)
        await model.load()
        return model
    }

    @Test func storedTagsMarkFieldsMachineTranslated() async {
        let model = await makeModel(store: taggedStore())
        #expect(model.draft(.description, in: .german).isMachineTranslated)
        #expect(model.machineTranslatedFields(in: .german) == [.description])
        #expect(model.coverage?.summary.machineTranslatedCount == 1)
    }

    @Test func aTagOnlyCountsWhileTheTextIsTheSame() async {
        let store = InMemoryMachineTranslationStore()
        store.setTags([descriptionKey.id: "An older text"], appID: app.id, scope: versionScope)
        let model = await makeModel(store: store)
        #expect(!model.draft(.description, in: .german).isMachineTranslated)
    }

    @Test func markReviewedClearsTheTagWithoutQueueingAnything() async {
        let store = taggedStore()
        let queue = ChangeQueue()
        let model = await makeModel(store: store, queue: queue)
        model.markReviewed(.description, in: .german)
        #expect(!model.draft(.description, in: .german).isMachineTranslated)
        #expect(store.tags(appID: app.id, scope: versionScope).isEmpty)
        #expect(queue.changes.isEmpty)
    }

    @Test func markAllReviewedClearsTheLocale() async {
        let store = taggedStore()
        let model = await makeModel(store: store)
        model.markAllReviewed(in: .german)
        #expect(model.machineTranslatedFields(in: .german).isEmpty)
        #expect(store.tags(appID: app.id, scope: versionScope).isEmpty)
    }

    @Test func editingCountsAsReviewing() async {
        let store = taggedStore()
        let queue = ChangeQueue()
        let model = await makeModel(store: store, queue: queue)
        model.edit(.description, in: .german, to: "Lumen hält alles privat.")
        #expect(!model.draft(.description, in: .german).isMachineTranslated)
        #expect(store.tags(appID: app.id, scope: versionScope).isEmpty)
        #expect(queue.changes.first?.source == .you)
    }

    @Test func acceptedTranslationsStayTaggedAcrossRelaunch() async throws {
        let store = InMemoryMachineTranslationStore()
        let queue = ChangeQueue()
        let model = await makeModel(store: store, queue: queue)
        model.presentTranslate(scope: TranslationScope(fields: [.keywords], locales: [.german]))
        model.startTranslation()
        await model.translation.waitUntilFinished()
        model.translation.acceptAll()
        model.finishSuggestions()

        let change = try #require(queue.change(id: StorePageContentFixtures.changeID(.german, .keywords)))
        #expect(change.source == .machineTranslation)
        #expect(change.newValue == "[de-DE] diary,mood,gratitude")
        #expect(store.tags(appID: app.id, scope: versionScope)[ListingFieldKey(.german, .keywords).id] == change.newValue)

        let relaunched = await makeModel(store: store, queue: queue)
        #expect(relaunched.draft(.keywords, in: .german).isMachineTranslated)
        #expect(relaunched.value(.keywords, in: .german) == change.newValue)
    }

    @Test func discardingAnAcceptedTranslationForgetsItsTag() async {
        let store = InMemoryMachineTranslationStore()
        let queue = ChangeQueue()
        let model = await makeModel(store: store, queue: queue)
        model.presentTranslate(scope: TranslationScope(fields: [.keywords], locales: [.german]))
        model.startTranslation()
        await model.translation.waitUntilFinished()
        model.translation.acceptAll()
        model.finishSuggestions()

        queue.discardAll { _ in true }
        model.queueDidChange()
        #expect(model.value(.keywords, in: .german).isEmpty)
        #expect(store.tags(appID: app.id, scope: versionScope).isEmpty)
    }

    @Test func reviewingTellsTheOverviewItsNumbersChanged() async {
        var services = WorkspaceServices.debug
        let store = taggedStore()
        services.storePage = FakeStorePageServices(machineTranslations: store)
        let summaries = AppSummaryStore(services: services)
        await summaries.load(app)
        #expect(summaries.storePage[app.id]?.value?.machineTranslatedCount == 1)

        let model = await makeModel(store: store, summaries: summaries)
        #expect(summaries.storePage[app.id]?.value != nil)
        model.markReviewed(.description, in: .german)
        #expect(summaries.storePage[app.id]?.value == nil)
    }

    @Test func theFileStoreKeepsTagsBetweenLaunches() {
        let url = URL.temporaryDirectory.appending(path: "MachineTranslations-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let first = FileMachineTranslationStore(url: url)
        first.setTags(["de-DE.keywords": "tagebuch"], appID: "app1", scope: versionScope)

        let second = FileMachineTranslationStore(url: url)
        #expect(second.tags(appID: "app1", scope: versionScope) == ["de-DE.keywords": "tagebuch"])
        #expect(second.tags(appID: "app2", scope: versionScope).isEmpty)
        second.setTags([:], appID: "app1", scope: versionScope)
        #expect(FileMachineTranslationStore(url: url).tags(appID: "app1", scope: versionScope).isEmpty)
    }

    @Test func appLevelAndVersionTagsLiveInTheirOwnScopes() {
        let store = InMemoryMachineTranslationStore()
        store.setTags(["de-DE.subtitle": "Notizen"], appID: "app1", scope: MachineTranslationScope.appInfo("info"))
        store.setTags(["de-DE.keywords": "tagebuch"], appID: "app1", scope: MachineTranslationScope.version("v2"))
        let tags = MachineTranslationScope.tags(in: store, appID: "app1", ids: StorePageContentFixtures.ids)
        #expect(tags == ["de-DE.subtitle": "Notizen", "de-DE.keywords": "tagebuch"])
        #expect(MachineTranslationScope.tags(in: store, appID: "app1", ids: StorePageContentFixtures.live.ids) == ["de-DE.subtitle": "Notizen"])
    }
}
