//
//  RetentionToolsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// `get_retention`, `propose_retention_message` and
/// `propose_retention_offer` on Lumen Journal's sample: what an assistant
/// reads, what it may queue in Review & Push, and what's refused with
/// App Store Connect's reasons.
@MainActor
@Suite("Retention MCP tools")
struct RetentionToolsTests {
    private let changes = ChangeQueue()
    private let store = RetentionDraftStore()
    private let lumen = DebugFixtures.AppID.lumen
    /// Images sent with a proposal, kept out of AppLocalizer's container.
    private let images = FileManager.default.temporaryDirectory.appending(path: "retention-tools-\(UUID().uuidString)")

    private func call(_ tool: some MCPTool, _ arguments: [String: JSONValue]) async throws -> MCPToolOutcome {
        let workspace = MCPTestFixtures.workspace(changes: changes)
        return try await tool.call(MCPToolArguments(arguments), in: MCPToolContext(workspace: workspace, clientName: "Claude Code"))
    }

    private func message(_ arguments: [String: JSONValue]) async throws -> MCPToolOutcome {
        var all: [String: JSONValue] = ["appId": "Lumen Journal"]
        all.merge(arguments) { $1 }
        return try await call(ProposeRetentionMessageTool(store: store, imageDirectory: images), all)
    }

    private func reasons(_ outcome: MCPToolOutcome) -> [String] {
        outcome.result["reasons"]?.arrayValue?.compactMap(\.stringValue) ?? []
    }

    // MARK: - Reading

    @Test func getRetentionReadsTheMessagesOffersAndLimits() async throws {
        let outcome = try await call(GetRetentionTool(store: store), ["appId": "Lumen Journal"])
        let result = outcome.result

        #expect(result["sourceLocale"] == "en-US")
        #expect(result["languages"]?.arrayValue?.count == 18)
        #expect(result["limits"]?["header"] == .int(66))
        #expect(result["limits"]?["body"] == .int(144))
        #expect(result["limits"]?["messagesPerApp"] == .int(10))
        let message = try #require(result["messages"]?.arrayValue?.first)
        #expect(message["referenceName"] == "Before you go")
        #expect(message["status"] == "live")
        #expect(message["texts"]?["de-DE"]?["header"] == "Alles, was du geschrieben hast, bleibt deins")
        #expect(result["offers"]?.arrayValue?.count == 2)
        #expect(result["subscriptions"]?.arrayValue?.first?["messageId"] == .string(RetentionSampleData.messageID))
        #expect(outcome.logLines.first?.outcome == MCPCallOutcome.read)
    }

    // MARK: - Messages

    @Test func aNewMessageInEnglishIsQueuedAsTheAssistants() async throws {
        let outcome = try await message([
            "referenceName": "Come back soon",
            "subscriptions": ["Monthly"],
            "locale": "en-US",
            "header": "Your journal waits for you",
            "body": "Cancel and your entries stay. Prompts, photos and search end with this period.",
            "evidence": ["Lumen/Paywall.swift:40 — lists prompts, photos and search"],
        ])

        #expect(outcome.result["status"] == "queued")
        let changeID = RetentionChangeBuilder.messageChangeID(appID: lumen, messageID: "draft-1")
        #expect(outcome.result["changeId"] == .string(changeID))
        #expect(outcome.result["missingLanguages"]?.arrayValue?.count == 17)
        #expect(outcome.result["replacesMessageOn"]?.arrayValue == [.string(RetentionSampleData.monthlyID)])
        let change = try #require(changes.change(id: changeID))
        #expect(change.blockedReason == nil)
        #expect(change.groupID == nil)
        #expect(change.creation?.fields.first { $0.id == "header.en-US" }?.source == .assistant(client: "Claude Code"))
        #expect(change.creation?.fields.contains { $0.id == "evidence" } == true)
        #expect(store.message(appID: lumen, id: "draft-1")?.referenceName == "Come back soon")
        #expect(store.isQueuedCopy(appID: lumen, id: "draft-1"))
    }

    @Test func anotherLanguageForTheLiveMessageMakesANewVersion() async throws {
        let outcome = try await message([
            "messageId": "Before you go",
            "texts": [["locale": "fi", "header": "Kaikki kirjoittamasi pysyy sinun", "body": "Jos perut, merkintäsi säilyvät."]],
        ])
        #expect(outcome.result["status"] == "queued")
        let change = try #require(changes.change(id: RetentionChangeBuilder.messageChangeID(appID: lumen, messageID: RetentionSampleData.messageID)))
        #expect(change.requests.contains { $0.path == RetentionRequests.versionsPath })
        #expect(change.requests.count { $0.path == RetentionRequests.localizationsPath } == 19)
    }

    @Test func wordsOverApplesLimitsAreRefusedWithTheirLengths() async throws {
        let outcome = try await message([
            "messageId": .string(RetentionSampleData.messageID),
            "locale": "de-DE",
            "body": .string(#require(RetentionSampleData.offer["de-DE"]).1),
        ])
        #expect(outcome.result["status"] == "refused")
        #expect(reasons(outcome) == ["de-DE: the body is 149 characters; Apple allows 144."])
        #expect(changes.changes.isEmpty)
        #expect(outcome.logLines.first?.outcome == MCPCallOutcome.refused)
    }

    @Test func aPushedMessageCantBeRenamed() async throws {
        let outcome = try await message(["messageId": "Before you go", "referenceName": "Wait"])
        #expect(outcome.result["status"] == "refused")
        #expect(reasons(outcome).first?.contains("can’t rename") == true)
    }

    @Test func whatAppStoreConnectHasAlreadyIsRefused() async throws {
        let english = try #require(RetentionSampleData.message["en-US"])
        let outcome = try await message(["messageId": "Before you go", "locale": "en-US", "header": .string(english.0), "body": .string(english.1)])
        #expect(reasons(outcome) == ["That’s what App Store Connect has already."])
    }

    @Test func anEleventhMessageIsRefused() async throws {
        for number in 1...9 {
            store.keep(RetentionTestFixtures.englishDraft(id: "draft-\(number)", name: "Message \(number)"), appID: lumen, queued: false)
        }
        let outcome = try await message([
            "referenceName": "One too many", "subscriptions": ["Annual"], "locale": "en-US", "header": "Stay", "body": "Your entries stay.",
        ])
        #expect(outcome.result["status"] == "refused")
        #expect(reasons(outcome) == [RetentionMessageProblem.tooManyMessages.message])
    }

    @Test func anOfferMessageNeedsAnOffer() async throws {
        let outcome = try await message([
            "referenceName": "Stay for less", "subscriptions": ["lumen.plus.monthly"], "kind": "offer",
            "locale": "en-US", "header": "Stay for half price", "body": "Three months at 50% off.",
        ])
        #expect(outcome.result["status"] == "queued")
        let outcome2 = try await message([
            "messageId": "Before you go", "kind": "image",
        ])
        #expect(reasons(outcome2) == [RetentionMessageProblem.noImage.message])
    }

    @Test func aShorterWordingWaitsForUseShorterVersion() async throws {
        let outcome = try await message([
            "messageId": .string(RetentionSampleData.messageID), "locale": "de-DE",
            "body": .string(RetentionSampleData.shorterGerman), "suggestion": .bool(true),
        ])
        #expect(outcome.result["status"] == "suggested")
        let suggestion = try #require(store.suggestion(appID: lumen, messageID: RetentionSampleData.messageID, locale: "de-DE"))
        #expect(suggestion.body == RetentionSampleData.shorterGerman)
        #expect(suggestion.header == nil)
        #expect(suggestion.client == "Claude Code")
        #expect(changes.changes.isEmpty)
    }

    @Test func anImageInBase64IsKeptForThePush() async throws {
        let png = try RetentionTestFixtures.pngData(width: 3840, height: 1000)
        let outcome = try await message(["messageId": "Before you go", "imageBase64": .string(png.base64EncodedString()), "imageName": "Moon test"])
        #expect(outcome.result["status"] == "queued")
        let kept = try #require(store.message(appID: lumen, id: RetentionSampleData.messageID))
        defer { try? FileManager.default.removeItem(at: images) }
        #expect(kept.kind == .image)
        #expect(kept.image?.pixelHeight == 1000)
        #expect(kept.image?.localPath?.hasPrefix(images.path) == true)
        let change = try #require(changes.changes.first)
        let placement = try #require(change.requests.first { $0.path == RetentionRequests.placementsPath })
        #expect(RetentionImageUpload(in: placement)?.path == kept.image?.localPath)
    }

    @Test func aTransparentImageIsRefused() async throws {
        let png = try RetentionTestFixtures.pngData(width: 3840, height: 1000, alpha: true)
        let outcome = try await message(["messageId": "Before you go", "imageBase64": .string(png.base64EncodedString())])
        #expect(reasons(outcome) == [RetentionImageProblem.transparency.message])
    }

    // MARK: - Offers

    @Test func anOfferIsQueuedWithTheMessageToShowIt() async throws {
        let outcome = try await call(ProposeRetentionOfferTool(store: store), [
            "appId": "Lumen Journal", "subscription": "Monthly", "mode": "PAY_UP_FRONT", "months": .int(3), "price": .double(9.99),
            "referenceName": "Three months for 9.99", "evidence": ["Plans.swift:22 — monthly is 4.99"],
        ])
        #expect(outcome.result["status"] == "queued")
        #expect(outcome.result["offerId"] == "retention.three_months_for_9_99")
        #expect(outcome.result["next"]?.stringValue?.contains("kind \"offer\"") == true)
        let change = try #require(changes.changes.first)
        #expect(change.source == .assistant(client: "Claude Code"))
        #expect(RetentionOfferCreate(change.requests[0])?.price?.amount == Decimal(string: "9.99"))
    }

    @Test func anOfferAppStoreConnectWouldRefuseIsListed() async throws {
        let outcome = try await call(ProposeRetentionOfferTool(store: store), [
            "appId": "Lumen Journal", "subscription": "Monthly", "mode": "PAY_AS_YOU_GO", "months": .int(3), "price": .double(5.99), "paidMonths": .int(30),
        ])
        #expect(outcome.result["status"] == "refused")
        #expect(reasons(outcome) == [
            RetentionOfferProblem.priceNotLower(usual: "$4.99").message,
            RetentionOfferProblem.invalidPaidMonths.message,
        ])
        #expect(changes.changes.isEmpty)
    }

    @Test func anUnknownSubscriptionNamesTheAppsOnes() async throws {
        await #expect(throws: MCPToolError.self) {
            try await call(
                ProposeRetentionOfferTool(store: store), ["appId": "Lumen Journal", "subscription": "Weekly", "mode": "FREE_TRIAL", "months": .int(1)]
            )
        }
    }

    @Test func theToolsAreInTheToolbox() {
        #expect(MCPToolbox.standard.toolNames.isSuperset(of: ["get_retention", "propose_retention_message", "propose_retention_offer"]))
    }

    /// Ask to Shorten It… is on drafts that were never pushed, too.
    @Test func aDraftCanBeOfferedAShorterWording() async throws {
        _ = try await message([
            "referenceName": "Come back soon", "subscriptions": ["Monthly"], "locale": "en-US",
            "header": "Your journal waits for you", "body": "Cancel and your entries stay.",
        ])
        let id = try #require(store.messages(for: lumen).first(where: \.isNew)?.id)
        let outcome = try await message(["messageId": .string(id), "locale": "en-US", "body": "Your entries stay.", "suggestion": true])
        #expect(outcome.result["status"] == "suggested")
        #expect(store.suggestion(appID: lumen, messageID: id, locale: "en-US")?.body == "Your entries stay.")
    }

    /// propose_retention_offer tells the assistant to do exactly this.
    @Test func turningAMessageIntoAnOfferMessageIsNotUnchanged() async throws {
        let outcome = try await message(["messageId": .string(RetentionSampleData.messageID), "kind": "offer"])
        #expect(outcome.result["status"] == "queued")
    }
}
#endif
