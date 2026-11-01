//
//  PushControllerDuplicateLocaleTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// A new Store Page locale App Store Connect refuses as a duplicate (it's
/// there by now): its texts go onto the localization that's there when
/// that overwrites nothing, and stay for review when it would.
@MainActor
@Suite("PushController duplicate locales")
struct PushControllerDuplicateLocaleTests {
    private let queue = ChangeQueue()
    private let history = PushHistory()

    private static let duplicate = AppStoreConnectError.rejected(
        statusCode: 409,
        code: "ENTITY_ERROR.ATTRIBUTE.INVALID.DUPLICATE",
        detail: "Entity with locale: fr-FR already exists. Try updating."
    )
    private static let versionLookup = "/v1/appStoreVersions/v2/appStoreVersionLocalizations?limit=200"

    /// French queued as a new page: name at the app level, description
    /// and promotional text at the version level.
    private static var frenchPage: [PendingChange] {
        var listing = StorePageContentFixtures.editable.listing()
        listing.addLocale(.french)
        listing.edit(.name, in: .french, to: "Lumen : Journal")
        listing.edit(.description, in: .french, to: "Un journal privé.")
        listing.edit(.promotionalText, in: .french, to: "Une question chaque jour.")
        return ListingChangeBuilder(appID: "app1", ids: StorePageContentFixtures.ids, versionString: "2.0").changes(for: listing)
    }

    private static func localizations(french attributes: String) -> Data {
        let german = #"{"type":"appStoreVersionLocalizations","id":"vl-de","attributes":{"locale":"de-DE","description":"Tagebuch"}}"#
        let french = #"{"type":"appStoreVersionLocalizations","id":"vl-fr","attributes":{"locale":"fr-FR",\#(attributes)}}"#
        return Data(#"{"data":[\#(german),\#(french)]}"#.utf8)
    }

    private func push(_ transport: FakePushTransport) async -> PushController {
        let controller = PushController(queue: queue, history: history, transport: transport)
        queue.upsert(contentsOf: Self.frenchPage)
        controller.push(queue.changes)
        await controller.waitUntilFinished()
        return controller
    }

    @Test func aLocaleThatIsThereEmptyGetsTheTextsInstead() async throws {
        let transport = FakePushTransport(
            createFailures: ["/v1/appStoreVersionLocalizations": Self.duplicate],
            remote: [Self.versionLookup: Self.localizations(french: #""description":null,"promotionalText":"""#)]
        )
        let push = await push(transport)

        #expect(push.title == "2 pushed")
        #expect(queue.changes.isEmpty)
        #expect(transport.fetched == [Self.versionLookup])
        #expect(transport.sent.map { "\($0.method.rawValue) \($0.path)" } == [
            "POST /v1/appInfoLocalizations",
            "POST /v1/appStoreVersionLocalizations",
            "PATCH /v1/appStoreVersionLocalizations/vl-fr",
        ])
        let update = try #require(StorePageWriteDocument.decode(transport.sent.last?.body))
        #expect(update.data.id == "vl-fr")
        #expect(update.data.attributes == ["description": "Un journal privé.", "promotionalText": "Une question chaque jour."])
    }

    @Test func aLocaleThatAlreadyHasTheseTextsNeedsNoUpdate() async {
        let transport = FakePushTransport(
            createFailures: ["/v1/appStoreVersionLocalizations": Self.duplicate],
            remote: [Self.versionLookup: Self.localizations(french: #""description":"Un journal privé.""#)]
        )
        let push = await push(transport)

        #expect(push.doneCount == 2)
        #expect(transport.sent.last?.path == "/v1/appStoreVersionLocalizations/vl-fr")
        #expect(queue.changes.isEmpty)
    }

    @Test func otherTextThereIsNotOverwritten() async {
        let transport = FakePushTransport(
            createFailures: ["/v1/appStoreVersionLocalizations": Self.duplicate],
            remote: [Self.versionLookup: Self.localizations(french: #""description":"Un autre texte.""#)]
        )
        let push = await push(transport)

        #expect(push.title == "1 pushed · 1 failed")
        #expect(!transport.sent.contains { $0.method == .patch })
        #expect(queue.changes.map(\.id) == ["storePage.app1.version.v2.fr-FR.new"])
        #expect(push.items.last?.status == .failed(
            "French is already in App Store Connect with its own Description, so nothing was overwritten. "
                + "Open the Store Page to review these as edits of what’s there."
        ))
    }

    @Test func aDuplicateThatCantBeFoundKeepsApplesError() async {
        let transport = FakePushTransport(
            createFailures: ["/v1/appStoreVersionLocalizations": Self.duplicate],
            remote: [Self.versionLookup: Data(#"{"data":[]}"#.utf8)]
        )
        let push = await push(transport)

        #expect(push.items.last?.status == .failed(
            "ENTITY_ERROR.ATTRIBUTE.INVALID.DUPLICATE — Entity with locale: fr-FR already exists. Try updating."
        ))
        #expect(queue.changes.count == 1)
    }

    @Test func otherRefusalsAreNotLookedUp() async {
        let invalid = AppStoreConnectError.rejected(statusCode: 409, code: "ENTITY_ERROR.ATTRIBUTE.INVALID", detail: "Too long.")
        let transport = FakePushTransport(createFailures: ["/v1/appStoreVersionLocalizations": invalid])
        let push = await push(transport)

        #expect(transport.fetched.isEmpty)
        #expect(push.items.last?.status == .failed("ENTITY_ERROR.ATTRIBUTE.INVALID — Too long."))
    }
}
