//
//  RetentionMessageCreate.swift
//  AppLocalizer
//

import Foundation

/// A new retention message's `POST /v1/retentionMessages`. A push that
/// stopped after it sends it again on a retry; when App Store Connect
/// refuses it, the push looks for the app's message with that reference
/// name (names are the person's own and can't change) and carries on
/// with it.
struct RetentionMessageCreate: Hashable, Sendable {
    var request: PushRequest
    var appID: StoreApp.ID
    var referenceName: String

    init?(_ request: PushRequest) {
        guard request.method == .post, request.path == RetentionRequests.messagesPath,
              let data = RetentionRequests.object(of: request)?["data"] as? [String: Any],
              let name = RetentionJSON.string("referenceName", of: data),
              let appID = RetentionJSON.relatedID("app", of: data)
        else { return nil }
        self.request = request
        self.appID = appID
        referenceName = name
    }

    var lookupPath: String {
        "/v1/apps/\(appID)/retentionMessages?fields%5BretentionMessages%5D=referenceName&limit=200"
    }

    /// Creates the message, or finds the one a push made before; returns
    /// its ID.
    @MainActor
    func send(via transport: any PushTransport, note: (AppStoreConnectRateLimit?) -> Void) async throws -> String {
        do {
            let response = try await transport.send(request)
            note(response.rateLimit)
            guard let id = RetentionJSON.resource(in: response.data)?.id else { throw AppStoreConnectError.unexpectedPayload }
            return id
        } catch let refusal as AppStoreConnectError {
            guard NewSubscriptionCreate.mayBeTaken(refusal) else { throw refusal }
            let found = try await RetentionJSON.resources(at: lookupPath, via: transport, note: note)
            guard let id = found.data.first(where: { RetentionJSON.string("referenceName", of: $0) == referenceName })?["id"] as? String
            else { throw refusal }
            return id
        }
    }
}
