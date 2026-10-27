//
//  StorePageViewModelTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("StorePageViewModel")
struct StorePageViewModelTests {
    private let app = StorePageContentFixtures.app

    private func makeModel(
        services: FakeStorePageServices = FakeStorePageServices(),
        queue: ChangeQueue = ChangeQueue(),
        summaries: AppSummaryStore? = nil,
        push: PushController? = nil
    ) async -> StorePageViewModel {
        let model = StorePageViewModel(app: app, services: services, queue: queue, summaries: summaries, push: push)
        await model.load()
        return model
    }

    // MARK: - Loading

    @Test func loadsTheEditableVersionWithAppStoreConnectsTexts() async {
        let model = await makeModel()
        #expect(model.content?.version.id == "v2")
        #expect(model.isVersionEditable)
        #expect(model.value(.name, in: .german) == "Lumen: Tagebuch")
        #expect(model.value(.keywords, in: .german).isEmpty)
        #expect(model.coverage?.rows.map(\.locale) == [.englishUS, .german])
        #expect(model.summaryLine.contains("2 of"))
        #expect(model.mode == .coverage)
    }

    @Test func failedLoadSaysWhyAndReportsTheRateLimitToTheBanner() async {
        let services = FakeStorePageServices()
        services.error = AppStoreConnectError.rateLimited
        let queue = ChangeQueue()
        let push = PushController(queue: queue, history: PushHistory())
        let model = await makeModel(services: services, queue: queue, push: push)
        #expect(!model.isLoaded)
        #expect(model.errorMessage != nil)
        guard case .rateLimited = push.notice else {
            Issue.record("expected the rate-limit banner, got \(String(describing: push.notice))")
            return
        }
    }

    @Test func pickingTheLiveVersionMakesVersionFieldsReadOnly() async {
        let services = FakeStorePageServices()
        let model = await makeModel(services: services)
        await model.selectVersion("v19")
        #expect(services.contentRequests.last == "v19")
        #expect(model.content?.version.id == "v19")
        #expect(!model.isVersionEditable)
        #expect(!model.canEdit(.description))
        #expect(model.canEdit(.name))
    }

    @Test func noEditableVersionShowsTheNoVersionPageUntilAskedForTheLiveOne() async {
        let model = await makeModel(services: FakeStorePageServices(contents: [StorePageContentFixtures.liveOnly]))
        #expect(model.showsNoVersionPage)
        model.showsReadOnlyVersion = true
        #expect(!model.showsNoVersionPage)
        #expect(model.canEdit(.subtitle))
    }

    // MARK: - Editing and the queue

    @Test func anEditBecomesAPatchWithRestoreAndConflictCheck() async throws {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        model.edit(.subtitle, in: .german, to: "Notizen und Fragen")

        let change = try #require(queue.change(id: StorePageContentFixtures.changeID(.german, .subtitle)))
        let path = "/v1/appInfoLocalizations/il-de"
        #expect(change.appID == "app1")
        #expect(change.section == .storePage)
        #expect(change.group == "Store Page · App information")
        #expect(change.title == "German · Subtitle")
        #expect(change.flagRegion == "DE")
        #expect(change.oldValue == "Private Notizen, sanfte Fragen")
        #expect(change.newValue == "Notizen und Fragen")
        #expect(change.source == .you)
        #expect(change.blockedReason == nil)
        #expect(change.requests == [ListingChangeBuilder.patch(
            path: path, type: "appInfoLocalizations", id: "il-de", attributes: ["subtitle": "Notizen und Fragen"]
        )])
        #expect(change.restoreRequests == [ListingChangeBuilder.patch(
            path: path, type: "appInfoLocalizations", id: "il-de", attributes: ["subtitle": "Private Notizen, sanfte Fragen"]
        )])
        #expect(change.conflictCheck == ConflictCheck(path: path, keyPath: ["data", "attributes", "subtitle"], expected: "Private Notizen, sanfte Fragen"))
    }

    @Test func versionFieldsGoToTheVersionLocalization() async throws {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        model.edit(.keywords, in: .englishUS, to: "diary,mood")

        let change = try #require(queue.change(id: StorePageContentFixtures.changeID(.englishUS, .keywords)))
        #expect(change.group == "Store Page · Version 2.0")
        #expect(change.requests.first?.method == .patch)
        #expect(change.requests.first?.path == "/v1/appStoreVersionLocalizations/vl-en")
        let body = try #require(StorePageWriteDocument.decode(change.requests.first?.body))
        #expect(body.data.type == "appStoreVersionLocalizations")
        #expect(body.data.id == "vl-en")
        #expect(body.attribute("keywords") == "diary,mood")
    }

    @Test func typingTheOldTextBackRemovesTheChange() async {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        model.edit(.subtitle, in: .german, to: "Neu")
        #expect(queue.count(for: app.id) == 1)
        model.edit(.subtitle, in: .german, to: "Private Notizen, sanfte Fragen")
        #expect(queue.count(for: app.id) == 0)
    }

    @Test func overTheLimitStaysQueuedButCantBePushed() async throws {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        model.edit(.subtitle, in: .german, to: String(repeating: "a", count: 31))

        let change = try #require(queue.change(id: StorePageContentFixtures.changeID(.german, .subtitle)))
        #expect(change.blockedReason != nil)
        #expect(model.validation(of: .subtitle, in: .german).isBlocking)
        #expect(model.validation(of: .subtitle, in: .german).message == "1 character over the limit.")
    }

    @Test func anInvalidURLIsBlocked() async {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        model.edit(.supportURL, in: .german, to: "lumen.example/de/support")
        #expect(model.validation(of: .supportURL, in: .german) == .invalidURL)
        #expect(queue.changes.first?.blockedReason != nil)
    }

    @Test func discardingInReviewRevertsTheField() async {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        model.edit(.subtitle, in: .german, to: "Neu")
        queue.discard(id: StorePageContentFixtures.changeID(.german, .subtitle))
        model.queueDidChange()
        #expect(model.value(.subtitle, in: .german) == "Private Notizen, sanfte Fragen")
        #expect(!model.draft(.subtitle, in: .german).isPending)
    }

    @Test func queuedEditsShowAgainInANewViewModel() async {
        let queue = ChangeQueue()
        let services = FakeStorePageServices()
        let first = await makeModel(services: services, queue: queue)
        first.edit(.promotionalText, in: .german, to: "Neu: Wochenrückblicke")

        let second = await makeModel(services: services, queue: queue)
        #expect(second.value(.promotionalText, in: .german) == "Neu: Wochenrückblicke")
        #expect(second.draft(.promotionalText, in: .german).isPending)
        #expect(second.coverage?.rows.last?.cells.first { $0.key.field == .promotionalText }?.state == .edited)
    }

    @Test func readOnlyFieldsIgnoreEdits() async {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        await model.selectVersion("v19")
        model.edit(.description, in: .german, to: "Neu")
        #expect(queue.changes.isEmpty)
    }

    // MARK: - Locales

    @Test func addingALocaleShowsItEmptyAndOpensTheEditor() async {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        model.addLocale(.french)
        #expect(model.listing?.contains(.french) == true)
        #expect(model.isEmptyLocale(.french))
        #expect(model.mode == .editor)
        #expect(model.editorLocale == .french)
        #expect(queue.changes.isEmpty)
        #expect(!model.addableLocales.contains(.french))
    }

    @Test func aNewLocalesFieldsArePostedTogether() async throws {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        model.addLocale(.french)
        model.edit(.promotionalText, in: .french, to: "Nouveau")
        model.edit(.keywords, in: .french, to: "journal,humeur")

        let change = try #require(queue.change(id: "storePage.app1.version.v2.fr-FR.new"))
        #expect(queue.count(for: app.id) == 1)
        #expect(change.requests.count == 1)
        #expect(change.requests.first?.method == .post)
        #expect(change.requests.first?.path == "/v1/appStoreVersionLocalizations")
        let body = try #require(StorePageWriteDocument.decode(change.requests.first?.body))
        #expect(body.attribute("locale") == "fr-FR")
        #expect(body.attribute("promotionalText") == "Nouveau")
        #expect(body.attribute("keywords") == "journal,humeur")
        #expect(body.data.relationships?["appStoreVersion"]?.data.id == "v2")
        #expect(change.restoreRequests.isEmpty)
    }

    @Test func theEditorStepsThroughLocales() async {
        let model = await makeModel()
        model.openEditor(.englishUS)
        model.stepEditorLocale(by: 1)
        #expect(model.editorLocale == .german)
        model.stepEditorLocale(by: 1)
        #expect(model.editorLocale == .englishUS)
        model.stepEditorLocale(by: -1)
        #expect(model.editorLocale == .german)
    }

    @Test func switchingToTheEditorStartsOnTheFirstOtherLocale() async {
        let model = await makeModel()
        model.mode = .editor
        #expect(model.editorLocale == .german)
    }

    // MARK: - Intents

    @Test func intentsWaitForTheFirstLoad() async {
        let model = StorePageViewModel(app: app, services: FakeStorePageServices(), queue: ChangeQueue())
        model.handle(.translateMissing)
        #expect(model.sheet == nil)
        await model.load()
        #expect(model.sheet == .translate)
    }

    @Test func findAndImportIntentsOpenTheirPanels() async {
        let model = await makeModel()
        model.handle(.findAndReplace)
        #expect(model.sheet == .findReplace)
        model.sheet = nil
        model.handle(.importTranslations)
        #expect(model.isImporterPresented)
    }

    @Test func theScreenshotsIntentOpensScreenshots() async {
        let model = await makeModel()
        model.handle(.showScreenshots)
        #expect(model.mode == .screenshots)
    }

    @Test func onlyStorePageIntentsAreTaken() {
        #expect(StorePageViewModel.handles(.translateMissing))
        #expect(StorePageViewModel.handles(.showScreenshots))
        #expect(StorePageViewModel.handles(.search))
        #expect(!StorePageViewModel.handles(.reviewSuggestions))
        #expect(!StorePageViewModel.handles(.editPriceSchedule(productID: nil)))
    }
}
