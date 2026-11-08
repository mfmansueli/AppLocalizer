//
//  RetentionModelTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Pricing → Retention's model on Lumen Journal's sample: the live
/// message, New Message up to 10, edits kept and queued, Translate All
/// flagging what runs too long, and what Review & Push brings back after a
/// relaunch.
@MainActor
@Suite("Retention model")
struct RetentionModelTests {
    private typealias Fixtures = RetentionTestFixtures
    private let queue = ChangeQueue()
    private let store = RetentionDraftStore()

    private func model(store: RetentionDraftStore? = nil) async -> RetentionModel {
        let model = RetentionModel(app: Fixtures.app, services: DebugRetentionServices(), queue: queue, store: store ?? self.store)
        await model.load(subscriptions: [Fixtures.monthly, Fixtures.annual])
        return model
    }

    private func writeEnglish(_ model: RetentionModel, header: String = "Stay a little longer", body: String = "Your entries stay yours.") {
        model.selectedLocale = "en-US"
        model.setHeader(header)
        model.setBody(body)
    }

    @Test func theLiveMessageIsSelected() async throws {
        let model = await model()
        let message = try #require(model.selectedMessage)
        #expect(model.messages.count == 1)
        #expect(message.referenceName == "Before you go")
        #expect(model.status(of: message) == .live)
        #expect(model.languagesSummary(of: message) == "All 18 languages ready")
        #expect(model.listDetail(of: message) == "Lumen Plus Monthly and Annual · 18 languages")
        #expect(!model.hasChangesToQueue)
        #expect(!model.canRename)
    }

    @Test func aNewMessageIsADraftUntilItsQueued() async throws {
        let model = await model()
        model.newMessage()
        #expect(model.messages.count == 2)
        #expect(model.canRename)
        model.toggleSubscription(Fixtures.annual.id)
        writeEnglish(model)
        let id = try #require(model.selectedMessageID)
        #expect(try model.status(of: #require(model.selectedMessage)) == .draft)
        #expect(try model.languagesSummary(of: #require(model.selectedMessage)) == "1 of 18 languages written · Translate All fills in the rest")

        model.toggleQueue()
        let changeID = RetentionChangeBuilder.messageChangeID(appID: Fixtures.app.id, messageID: id)
        #expect(queue.change(id: changeID) != nil)
        #expect(try model.status(of: #require(model.selectedMessage)) == .queued)

        model.setBody("Your entries stay.")
        #expect(queue.change(id: changeID)?.creation?.fields.first { $0.id == "body.en-US" }?.newValue == "Your entries stay.")

        model.toggleQueue()
        #expect(queue.changes.isEmpty)
        #expect(model.messages.count == 2)
    }

    @Test func somethingMissingIsSaidInsteadOfQueued() async {
        let model = await model()
        model.newMessage()
        model.toggleQueue()
        #expect(queue.changes.isEmpty)
        #expect(model.notice == RetentionMessageProblem.noSubscriptions.message)
    }

    @Test func tenMessagesAtMost() async {
        let model = await model()
        for _ in 0..<12 { model.newMessage() }
        #expect(model.messages.count == RetentionLimits.messagesPerApp)
        #expect(!model.canAddMessage)
    }

    @Test func aDraftIsThereWhenThePageComesBack() async {
        let model = await model()
        model.newMessage()
        writeEnglish(model, header: "Hello again")
        let again = await self.model()
        #expect(again.messages.count == 2)
        #expect(again.messages.last?.text(for: "en-US").header == "Hello again")
    }

    @Test func aQueuedMessageIsReadBackAfterARelaunch() async throws {
        let model = await model()
        model.newMessage()
        model.toggleSubscription(Fixtures.monthly.id)
        writeEnglish(model)
        model.toggleQueue()

        let relaunched = await self.model(store: RetentionDraftStore())
        #expect(relaunched.messages.count == 2)
        let read = try #require(relaunched.messages.last)
        #expect(read.text(for: "en-US").header == "Stay a little longer")
        #expect(read.subscriptionIDs == [Fixtures.monthly.id])
        #expect(relaunched.status(of: read) == .queued)
    }

    @Test func aNewMessageTakenOutOfReviewAndPushIsGone() async throws {
        let model = await model()
        model.newMessage()
        model.toggleSubscription(Fixtures.monthly.id)
        writeEnglish(model)
        model.toggleQueue()
        let id = try #require(model.selectedMessageID)

        queue.discard(id: RetentionChangeBuilder.messageChangeID(appID: Fixtures.app.id, messageID: id))
        model.refresh()
        #expect(model.messages.map(\.id) == [RetentionSampleData.messageID])
    }

    @Test func aDeletedDraftLeavesTheList() async throws {
        let model = await model()
        model.newMessage()
        let draft = try #require(model.selectedMessage)
        model.discardDraft(draft)
        #expect(model.messages.count == 1)
        #expect(model.selectedMessageID == RetentionSampleData.messageID)
    }

    @Test func translateAllFillsTheRestAndFlagsWhatRunsTooLong() async throws {
        let model = await model()
        model.newMessage()
        model.toggleSubscription(Fixtures.monthly.id)
        writeEnglish(model)
        #expect(model.canTranslate)

        await model.translateAll(with: RetentionStubTranslator(longTarget: "de-DE", missing: ["hi"]), protector: GlossaryProtector(terms: ["Lumen"]))

        let message = try #require(model.selectedMessage)
        #expect(message.text(for: "fr-FR").header == "[fr-FR] Stay a little longer")
        #expect(message.text(for: "fr-FR").origin == .translated)
        #expect(message.text(for: "de-DE").isTooLong)
        #expect(message.text(for: "hi").isEmpty)
        #expect(model.notice?.hasPrefix("Translated 16 languages.") == true)
        #expect(model.notice?.contains("German") == true)
        #expect(model.notice?.contains("Hindi") == true)
        #expect(model.languagesSummary(of: message) == "16 of 18 languages ready · 1 too long")
    }

    @Test func translateAllKeepsWhatSomeoneWrote() async throws {
        let model = await model()
        model.newMessage()
        writeEnglish(model)
        model.selectedLocale = "ja"
        model.setHeader("手書きの見出し")
        model.setBody("手書きの本文")
        await model.translateAll(with: RetentionStubTranslator(), protector: GlossaryProtector(terms: []))
        #expect(model.selectedMessage?.text(for: "ja").header == "手書きの見出し")

        model.selectedLocale = "en-US"
        model.setHeader("Stay with us")
        #expect(try !model.languagesToTranslate(in: #require(model.selectedMessage)).contains { $0.code == "ja" })
        #expect(try model.languagesToTranslate(in: #require(model.selectedMessage)).contains { $0.code == "fr-FR" })
    }

    @Test func aShorterVersionReplacesTheLongOne() async throws {
        let model = await model()
        model.selectedLocale = "de-DE"
        try model.setBody(#require(RetentionSampleData.offer["de-DE"]).1)
        store.suggest(
            RetentionSuggestion(messageID: RetentionSampleData.messageID, locale: "de-DE", body: RetentionSampleData.shorterGerman, client: "Claude Code"),
            appID: Fixtures.app.id
        )
        #expect(model.selectedText.isTooLong)
        model.useSuggestion()
        #expect(model.selectedText.body == RetentionSampleData.shorterGerman)
        #expect(!model.selectedText.isTooLong)
        #expect(model.suggestion == nil)
    }

    @Test func anOfferWaitsInReviewAndPush() async throws {
        let model = await model()
        let draft = try #require(model.newOfferDraft())
        #expect(draft.subscriptionID == Fixtures.monthly.id)
        #expect(model.addOffer(draft))
        #expect(model.offers.count == 3)
        #expect(model.offers.last?.isQueued == true)
        #expect(queue.changes.count == 1)
    }

    @Test func choosingAnImageMakesItAnImageMessage() async {
        let model = await model()
        await model.loadLibrary()
        model.useImage(RetentionSampleData.window)
        #expect(model.selectedMessage?.kind == .image)
        #expect(model.selectedMessage?.image?.name == "Night Window")
        #expect(model.hasChangesToQueue)
        #expect(model.problems.isEmpty)
    }
}
#endif
