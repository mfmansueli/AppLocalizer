//
//  InAppDraftWrite.swift
//  AppLocalizer
//

import Foundation

/// An In-App Texts `POST` whose version is `{inAppDraft:<owner>}`: since
/// App Store Connect API 4.4.1 a subscription group's, subscription's or
/// in-app purchase's texts are written into a version that takes edits.
/// When the In-App Texts were read none did (none yet, or the last one is
/// submitted or approved), so the push finds it now or creates a draft
/// (one per owner and push, shared by every locale's change). A new draft
/// copies the current texts, so a locale it has is updated instead of
/// created.
struct InAppDraftWrite: Hashable, Sendable {
    /// `subscriptionGroups`, `subscriptions` or `inAppPurchases`.
    var ownerType: String
    var ownerID: String
    /// `subscriptionGroupLocalizations`, `subscriptionLocalizations` or
    /// `inAppPurchaseLocalizations`.
    var localizationType: String
    /// `subscriptionGroupVersions`, `subscriptionVersions` or
    /// `inAppPurchaseVersions`.
    var versionType: String
    var locale: String
    /// The texts with `locale`.
    var attributes: [String: String?]

    /// The owner's place in the versions API: its versions list and the
    /// relationship a new version names it by.
    private static let owners: [String: (versions: String, versionType: String, relationship: String)] = [
        "subscriptionGroups": ("/v1/subscriptionGroups/%@/versions", "subscriptionGroupVersions", "subscriptionGroup"),
        "subscriptions": ("/v1/subscriptions/%@/versions", "subscriptionVersions", "subscription"),
        "inAppPurchases": ("/v2/inAppPurchases/%@/versions", "inAppPurchaseVersions", "inAppPurchase"),
    ]

    init?(_ request: PushRequest) {
        guard request.method == .post,
              let document = StorePageWriteDocument.decode(request.body),
              request.path == "/v2/\(document.data.type)",
              let version = document.data.relationships?["version"]?.data,
              version.id.hasPrefix("{inAppDraft:"), version.id.hasSuffix("}"),
              let locale = document.attribute("locale")
        else { return nil }
        let owner = version.id.dropFirst("{inAppDraft:".count).dropLast().split(separator: "/", maxSplits: 1).map(String.init)
        guard owner.count == 2, Self.owners[owner[0]] != nil else { return nil }
        ownerType = owner[0]
        ownerID = owner[1]
        localizationType = document.data.type
        versionType = version.type
        self.locale = locale
        attributes = document.data.attributes
    }

    /// Caches the draft's ID for the push: `subscriptionGroups/123`.
    var ownerKey: String { "\(ownerType)/\(ownerID)" }

    /// `GET` the owner's versions.
    var versionsPath: String {
        String(format: Self.owners[ownerType]?.versions ?? "", ownerID) + "?limit=200"
    }

    /// `POST` a draft version, which copies the current texts.
    var createVersion: PushRequest {
        let relationship = Self.owners[ownerType]?.relationship ?? ""
        let body: [String: Any] = [
            "data": [
                "type": versionType,
                "relationships": [relationship: ["data": ["type": ownerType, "id": ownerID]]],
            ],
        ]
        let data = (try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])) ?? Data()
        return PushRequest(method: .post, path: "/v1/\(versionType)", body: data)
    }

    /// `GET` a version's localizations.
    func localizationsPath(versionID: String) -> String {
        "/v1/\(versionType)/\(versionID)/localizations?limit=200"
    }

    /// The newest version in the list that takes edits.
    static func editableVersionID(in data: Data) -> String? {
        resources(in: data)
            .filter { InAppTextsContent.editableVersionStates.contains(($0["attributes"] as? [String: Any])?["state"] as? String ?? "") }
            .max { version(of: $0) < version(of: $1) }?["id"] as? String
    }

    /// The draft's localization for `locale`, if it has one.
    func existingLocalizationID(in data: Data) -> String? {
        Self.resources(in: data).first { ($0["attributes"] as? [String: Any])?["locale"] as? String == locale }?["id"] as? String
    }

    /// `POST /v2/<type>` into the version.
    func create(versionID: String) -> PushRequest {
        let document = StorePageWriteDocument.create(
            type: localizationType,
            attributes: attributes,
            parent: "version",
            parentType: versionType,
            parentID: versionID
        )
        return PushRequest(method: .post, path: "/v2/\(localizationType)", body: document.encoded())
    }

    /// `PATCH /v2/<type>/<id>` with the texts (a locale can't change).
    func update(id: String) -> PushRequest {
        let texts = attributes.filter { $0.key != "locale" }
        let document = StorePageWriteDocument.update(type: localizationType, id: id, attributes: texts)
        return PushRequest(method: .patch, path: "/v2/\(localizationType)/\(id)", body: document.encoded())
    }

    /// Sends it: into `knownVersionID`, else the newest version that takes
    /// edits, else a new draft; then updates the locale's localization when
    /// the version has it, or creates it. Returns the version and the
    /// localization, with the last response's rate limit.
    func send(
        via transport: any PushTransport,
        knownVersionID: String?
    ) async throws -> (versionID: String, localizationID: String?, rateLimit: AppStoreConnectRateLimit?) {
        var rateLimit: AppStoreConnectRateLimit?
        let versionID: String
        if let knownVersionID {
            versionID = knownVersionID
        } else {
            let versions = try await transport.fetch(versionsPath)
            rateLimit = versions.rateLimit
            if let editable = Self.editableVersionID(in: versions.data) {
                versionID = editable
            } else {
                let created = try await transport.send(createVersion)
                rateLimit = created.rateLimit
                guard let id = Self.createdID(in: created.data) else { throw AppStoreConnectError.unexpectedPayload }
                versionID = id
            }
        }
        let localizations = try await transport.fetch(localizationsPath(versionID: versionID))
        if let id = existingLocalizationID(in: localizations.data) {
            let response = try await transport.send(update(id: id))
            return (versionID, id, response.rateLimit ?? localizations.rateLimit ?? rateLimit)
        }
        let response = try await transport.send(create(versionID: versionID))
        return (versionID, Self.createdID(in: response.data), response.rateLimit ?? localizations.rateLimit ?? rateLimit)
    }

    private static func createdID(in data: Data) -> String? {
        let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (object?["data"] as? [String: Any])?["id"] as? String
    }

    private static func resources(in data: Data) -> [[String: Any]] {
        let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        return object?["data"] as? [[String: Any]] ?? []
    }

    private static func version(of resource: [String: Any]) -> Int {
        (resource["attributes"] as? [String: Any])?["version"] as? Int ?? 0
    }
}
