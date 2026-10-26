//
//  StorePageWriteDocument.swift
//  AppLocalizer
//

import Foundation

/// The JSON:API body of a Store Page write: `PATCH` one localization's
/// attributes, or `POST` a new localization with its parent relationship.
/// Empty values are sent as `null`, which clears the field.
///
/// The same document is read back from a queued `PendingChange`, so the
/// grid and editor show exactly what Review & Push would send.
struct StorePageWriteDocument: Codable, Hashable, Sendable {
    var data: Resource

    struct Resource: Codable, Hashable, Sendable {
        var type: String
        var id: String?
        var attributes: [String: String?]
        var relationships: [String: Relationship]?
    }

    struct Relationship: Codable, Hashable, Sendable {
        var data: Identifier
    }

    struct Identifier: Codable, Hashable, Sendable {
        var type: String
        var id: String
    }

    /// `PATCH /v1/<type>/<id>` with these attributes.
    static func update(type: String, id: String, attributes: [String: String?]) -> StorePageWriteDocument {
        StorePageWriteDocument(data: Resource(type: type, id: id, attributes: attributes, relationships: nil))
    }

    /// `POST /v1/<type>` creating a resource under `parent`, e.g. a version
    /// localization under `appStoreVersion`.
    static func create(
        type: String,
        attributes: [String: String?],
        parent relationship: String,
        parentType: String,
        parentID: String
    ) -> StorePageWriteDocument {
        let parent = Relationship(data: Identifier(type: parentType, id: parentID))
        return StorePageWriteDocument(data: Resource(type: type, id: nil, attributes: attributes, relationships: [relationship: parent]))
    }

    /// The attribute as a string; nil when it's absent or null.
    func attribute(_ name: String) -> String? {
        data.attributes[name] ?? nil
    }

    /// Sorted keys, so the same change always encodes to the same bytes.
    func encoded() -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return (try? encoder.encode(self)) ?? Data()
    }

    /// The document in a queued request's body, if it is one.
    static func decode(_ body: Data?) -> StorePageWriteDocument? {
        guard let body else { return nil }
        return try? JSONDecoder().decode(StorePageWriteDocument.self, from: body)
    }
}
