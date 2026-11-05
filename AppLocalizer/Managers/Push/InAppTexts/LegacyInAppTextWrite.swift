//
//  LegacyInAppTextWrite.swift
//  AppLocalizer
//

import Foundation

/// A pre-4.4.1 `/v1` write of a subscription group's or subscription's
/// texts: queued before AppLocalizer wrote into versions, or for an owner it
/// read as legacy. App Store Connect refuses those now
/// (`ENTITY_ERROR.ATTRIBUTE.INVALID.UNMODIFIABLE`), so the push sends the
/// same texts into the owner's editable version or a new draft instead
/// (`InAppDraftWrite`). A `POST` names its owner; a `PATCH` names only the
/// localization, so it's read first for its owner and locale.
struct LegacyInAppTextWrite: Hashable, Sendable {
    /// `subscriptionGroupLocalizations` or `subscriptionLocalizations`.
    var localizationType: String
    /// The localization a `PATCH` writes; nil for a `POST`.
    var localizationID: String?
    /// A `POST`'s owner; a `PATCH`'s is read with `lookupPath`.
    var ownerID: String?
    /// The texts, with `locale` for a `POST`.
    var attributes: [String: String?]

    private static let owners: [String: (ownerType: String, relationship: String, versionType: String)] = [
        "subscriptionGroupLocalizations": ("subscriptionGroups", "subscriptionGroup", "subscriptionGroupVersions"),
        "subscriptionLocalizations": ("subscriptions", "subscription", "subscriptionVersions"),
    ]

    init?(_ request: PushRequest) {
        guard let document = StorePageWriteDocument.decode(request.body),
              let owner = Self.owners[document.data.type]
        else { return nil }
        let base = "/v1/\(document.data.type)"
        switch request.method {
        case .post where request.path == base:
            guard let id = document.data.relationships?[owner.relationship]?.data.id else { return nil }
            ownerID = id
            localizationID = nil
        case .patch:
            guard let id = document.data.id, request.path == "\(base)/\(id)" else { return nil }
            ownerID = nil
            localizationID = id
        default:
            return nil
        }
        localizationType = document.data.type
        attributes = document.data.attributes
    }

    private var owner: (ownerType: String, relationship: String, versionType: String) {
        Self.owners[localizationType] ?? ("", "", "")
    }

    /// `GET` a `PATCH`'s localization with its owner.
    var lookupPath: String? {
        localizationID.map { "/v1/\(localizationType)/\($0)?include=\(owner.relationship)" }
    }

    /// The same texts as a write into the owner's editable version or a
    /// draft. A `PATCH` reads its localization first; `note` gets that
    /// response's rate limit.
    @MainActor
    func draftWrite(via transport: any PushTransport, note: (AppStoreConnectRateLimit?) -> Void) async throws -> InAppDraftWrite {
        var ownerID = ownerID
        var attributes = attributes
        if let lookupPath {
            let response = try await transport.fetch(lookupPath)
            note(response.rateLimit)
            let object = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any]
            let data = object?["data"] as? [String: Any]
            let relationship = (data?["relationships"] as? [String: Any])?[owner.relationship] as? [String: Any]
            ownerID = (relationship?["data"] as? [String: Any])?["id"] as? String
            attributes["locale"] = (data?["attributes"] as? [String: Any])?["locale"] as? String
        }
        guard let ownerID, let locale = attributes["locale"] ?? nil else { throw AppStoreConnectError.unexpectedPayload }
        return InAppDraftWrite(
            ownerType: owner.ownerType,
            ownerID: ownerID,
            localizationType: localizationType,
            versionType: owner.versionType,
            locale: locale,
            attributes: attributes
        )
    }
}
