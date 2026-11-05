//
//  SubscriptionGroupPlaceholder.swift
//  AppLocalizer
//

import Foundation

/// `{subscriptionGroup:<appID>:<referenceName>}` in a new subscription's
/// requests: the app's subscription group with that reference name. The
/// push looks it up and creates it when the app doesn't have it yet, so two
/// new subscriptions in the same new group share it, and a retry or a later
/// push doesn't make a second one. The reference name is percent-encoded,
/// so the placeholder is safe in a path and a JSON string (a `/` could be
/// written escaped there, so the parts are split by `:`).
struct SubscriptionGroupPlaceholder: Hashable, Sendable {
    var appID: String
    var referenceName: String
    /// The placeholder as it's written in the request.
    var token: String

    static func placeholder(appID: String, referenceName: String) -> String {
        "{subscriptionGroup:\(appID):\(encoded(referenceName))}"
    }

    /// The first one in the request's path or body.
    init?(in request: PushRequest) {
        let body = request.body.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        for text in [request.path, body] {
            guard let start = text.range(of: "{subscriptionGroup:"),
                  let end = text[start.upperBound...].firstIndex(of: "}")
            else { continue }
            let parts = text[start.upperBound..<end].split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2, let name = parts[1].removingPercentEncoding, !parts[0].isEmpty, !name.isEmpty else { return nil }
            appID = parts[0]
            referenceName = name
            token = String(text[start.lowerBound...end])
            return
        }
        return nil
    }

    /// `GET` the app's groups with that reference name.
    var lookupPath: String {
        "/v1/apps/\(appID)/subscriptionGroups?filter%5BreferenceName%5D=\(Self.encoded(referenceName))"
            + "&fields%5BsubscriptionGroups%5D=referenceName&limit=200"
    }

    /// The group with exactly that reference name; App Store Connect's
    /// filter may match more loosely.
    func groupID(in data: Data) -> String? {
        let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        let groups = object?["data"] as? [[String: Any]] ?? []
        return groups.first { ($0["attributes"] as? [String: Any])?["referenceName"] as? String == referenceName }?["id"] as? String
    }

    /// `POST /v1/subscriptionGroups`.
    var create: PushRequest {
        let body: [String: Any] = [
            "data": [
                "type": "subscriptionGroups",
                "attributes": ["referenceName": referenceName],
                "relationships": ["app": ["data": ["type": "apps", "id": appID]]],
            ],
        ]
        let data = (try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])) ?? Data()
        return PushRequest(method: .post, path: "/v1/subscriptionGroups", body: data)
    }

    /// Finds the group or creates it. Returns its ID and the last
    /// response's rate limit.
    func send(via transport: any PushTransport) async throws -> (id: String, rateLimit: AppStoreConnectRateLimit?) {
        let found = try await transport.fetch(lookupPath)
        if let id = groupID(in: found.data) { return (id, found.rateLimit) }
        let created = try await transport.send(create)
        let object = try? JSONSerialization.jsonObject(with: created.data) as? [String: Any]
        guard let id = (object?["data"] as? [String: Any])?["id"] as? String else { throw AppStoreConnectError.unexpectedPayload }
        return (id, created.rateLimit ?? found.rateLimit)
    }

    private static func encoded(_ name: String) -> String {
        name.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? name
    }
}
