//
//  NewSubscriptionCreateTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// A new subscription's `POST`: created, or found in its group when a push
/// before created it.
@MainActor
@Suite("NewSubscriptionCreate")
struct NewSubscriptionCreateTests {
    private static let productID = "com.rainbowmatch.premium.monthly"
    private static let lookup = "/v1/subscriptionGroups/22548879/subscriptions?filter%5BproductId%5D=com%2Erainbowmatch%2Epremium%2Emonthly"
        + "&fields%5Bsubscriptions%5D=productId&limit=200"
    private static let duplicate = AppStoreConnectError.rejected(
        statusCode: 409,
        code: "ENTITY_ERROR.ATTRIBUTE.INVALID.DUPLICATE",
        detail: "The product ID has already been used."
    )

    private static var request: PushRequest {
        let body: [String: Any] = ["data": [
            "type": "subscriptions",
            "attributes": ["name": "Bruma Premium Monthly", "productId": productID, "subscriptionPeriod": "ONE_MONTH"],
            "relationships": ["group": ["data": ["type": "subscriptionGroups", "id": "22548879"]]],
        ]]
        return PushRequest(method: .post, path: "/v1/subscriptions", body: try? JSONSerialization.data(withJSONObject: body))
    }

    private static func subscriptions(_ pairs: [(id: String, productID: String)]) -> Data {
        let items = pairs.map { #"{"id":"\#($0.id)","attributes":{"productId":"\#($0.productID)"}}"# }
        return Data(#"{"data":[\#(items.joined(separator: ","))]}"#.utf8)
    }

    @Test func readsTheProductAndTheGroup() throws {
        let create = try #require(NewSubscriptionCreate(Self.request))
        #expect(create.productID == Self.productID)
        #expect(create.groupID == "22548879")
        #expect(create.lookupPath == Self.lookup)
        #expect(NewSubscriptionCreate(PushRequest(method: .post, path: "/v1/subscriptionGroups", body: Self.request.body)) == nil)
        #expect(NewSubscriptionCreate(PushRequest(method: .post, path: "/v1/subscriptions")) == nil)
    }

    @Test func aNewSubscriptionGetsItsID() async throws {
        let transport = FakePushTransport(responses: ["/v1/subscriptions": Data(#"{"data":{"type":"subscriptions","id":"6831136732"}}"#.utf8)])
        let create = try #require(NewSubscriptionCreate(Self.request))
        let id = try await create.send(via: transport) { _ in }
        #expect(id == "6831136732")
        #expect(transport.fetched.isEmpty)
    }

    @Test func refusedAndFoundInTheGroupGivesTheExistingID() async throws {
        let found = Self.subscriptions([("6831136738", "com.rainbowmatch.premium.yearly"), ("6831136732", Self.productID)])
        let transport = FakePushTransport(createFailures: ["/v1/subscriptions": Self.duplicate], remote: [Self.lookup: found])
        let create = try #require(NewSubscriptionCreate(Self.request))
        let id = try await create.send(via: transport) { _ in }
        #expect(id == "6831136732")
        #expect(transport.fetched == [Self.lookup])
    }

    @Test func refusedAndNotFoundRethrowsTheRefusal() async throws {
        let others = Self.subscriptions([("6831136738", "com.rainbowmatch.premium.yearly")])
        let transport = FakePushTransport(createFailures: ["/v1/subscriptions": Self.duplicate], remote: [Self.lookup: others])
        let create = try #require(NewSubscriptionCreate(Self.request))
        await #expect(throws: Self.duplicate) { try await create.send(via: transport) { _ in } }
    }

    @Test func aBadRequestIsLookedUpToo() async throws {
        let badRequest = AppStoreConnectError.server(statusCode: 400, code: "PARAMETER_ERROR.INVALID", detail: "productId is in use.")
        let found = Self.subscriptions([("6831136732", Self.productID)])
        let transport = FakePushTransport(createFailures: ["/v1/subscriptions": badRequest], remote: [Self.lookup: found])
        let create = try #require(NewSubscriptionCreate(Self.request))
        #expect(try await create.send(via: transport) { _ in } == "6831136732")
    }

    @Test func otherFailuresAreNotLookedUp() async throws {
        let transport = FakePushTransport(createFailures: ["/v1/subscriptions": AppStoreConnectError.server(statusCode: 500, detail: nil)])
        let create = try #require(NewSubscriptionCreate(Self.request))
        await #expect(throws: AppStoreConnectError.server(statusCode: 500, detail: nil)) { try await create.send(via: transport) { _ in } }
        #expect(transport.fetched.isEmpty)
    }
}
