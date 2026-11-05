//
//  NewSubscriptionCreate.swift
//  AppLocalizer
//

import Foundation

/// A new subscription's `POST /v1/subscriptions`. A push that stopped after
/// it (a later step failed, then the app quit) sends it again; App Store
/// Connect refuses the product ID it already has, so the push looks the
/// subscription up in its group and carries on with that one instead of
/// failing at the first step forever.
struct NewSubscriptionCreate: Hashable, Sendable {
    var request: PushRequest
    var productID: String
    /// Filled in by then (no `{subscriptionGroup:…}` left).
    var groupID: String

    static let path = "/v1/subscriptions"

    init?(_ request: PushRequest) {
        guard request.method == .post, request.path == Self.path, let body = request.body,
              let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
              let data = object["data"] as? [String: Any],
              let productID = (data["attributes"] as? [String: Any])?["productId"] as? String,
              let group = ((data["relationships"] as? [String: Any])?["group"] as? [String: Any])?["data"] as? [String: Any],
              let groupID = group["id"] as? String
        else { return nil }
        self.request = request
        self.productID = productID
        self.groupID = groupID
    }

    /// `GET` the group's subscriptions with that product ID.
    var lookupPath: String {
        let encoded = productID.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? productID
        return "/v1/subscriptionGroups/\(groupID)/subscriptions?filter%5BproductId%5D=\(encoded)"
            + "&fields%5Bsubscriptions%5D=productId&limit=200"
    }

    /// The subscription with exactly that product ID.
    func subscriptionID(in data: Data) -> String? {
        let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        let subscriptions = object?["data"] as? [[String: Any]] ?? []
        return subscriptions.first { ($0["attributes"] as? [String: Any])?["productId"] as? String == productID }?["id"] as? String
    }

    /// A refusal that may mean the product ID is taken: 409 or 422
    /// (`.rejected`), or a 400. Apple's spec lists all three for this
    /// `POST`; anything else (rate limit, key, server) isn't looked up.
    static func mayBeTaken(_ refusal: AppStoreConnectError) -> Bool {
        switch refusal {
        case .rejected: true
        case let .server(statusCode, _, _): statusCode == 400
        default: false
        }
    }

    /// Creates the subscription, or finds the one a push made before.
    /// Returns its ID; `note` gets each response's rate limit. Throws
    /// App Store Connect's refusal when the group doesn't have it.
    @MainActor
    func send(via transport: any PushTransport, note: (AppStoreConnectRateLimit?) -> Void) async throws -> String {
        do {
            let response = try await transport.send(request)
            note(response.rateLimit)
            let object = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any]
            guard let id = (object?["data"] as? [String: Any])?["id"] as? String else { throw AppStoreConnectError.unexpectedPayload }
            return id
        } catch let refusal as AppStoreConnectError {
            guard Self.mayBeTaken(refusal) else { throw refusal }
            let found = try await transport.fetch(lookupPath)
            note(found.rateLimit)
            guard let id = subscriptionID(in: found.data) else { throw refusal }
            return id
        }
    }
}
