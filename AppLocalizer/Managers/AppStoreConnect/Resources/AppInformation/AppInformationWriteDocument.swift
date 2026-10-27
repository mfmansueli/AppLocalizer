//
//  AppInformationWriteDocument.swift
//  AppLocalizer
//

import Foundation

/// The JSON:API body of an App Information write: `PATCH` a resource's
/// attributes or to-one relationships (an app info's categories), or `POST`
/// a new resource under its parent (an accessibility declaration under the
/// app, review details under a version).
///
/// The same document is read back from a queued `PendingChange`, so the
/// pages show exactly what Review & Push would send.
struct AppInformationWriteDocument: Codable, Hashable, Sendable {
    var data: Resource

    struct Resource: Codable, Hashable, Sendable {
        var type: String
        var id: String?
        var attributes: [String: AppInformationAPIValue]?
        var relationships: [String: Relationship]?
    }

    /// A to-one relationship. `nil` data is sent as `null`, which removes
    /// it (e.g. no secondary category).
    struct Relationship: Codable, Hashable, Sendable {
        var data: Identifier?

        init(data: Identifier?) {
            self.data = data
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: RelationshipKey.self)
            data = try container.decodeIfPresent(Identifier.self, forKey: .data)
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: RelationshipKey.self)
            if let data {
                try container.encode(data, forKey: .data)
            } else {
                try container.encodeNil(forKey: .data)
            }
        }
    }

    /// `Relationship`'s one key, here so it isn't nested two levels deep.
    private enum RelationshipKey: String, CodingKey {
        case data
    }

    struct Identifier: Codable, Hashable, Sendable {
        var type: String
        var id: String
    }

    /// `PATCH /v1/<type>/<id>` with these attributes.
    static func update(type: String, id: String, attributes: [String: AppInformationAPIValue]) -> AppInformationWriteDocument {
        AppInformationWriteDocument(data: Resource(type: type, id: id, attributes: attributes, relationships: nil))
    }

    /// `PATCH /v1/<type>/<id>` setting to-one relationships, e.g. an app
    /// info's `primaryCategory`.
    static func update(type: String, id: String, relationships: [String: Relationship]) -> AppInformationWriteDocument {
        AppInformationWriteDocument(data: Resource(type: type, id: id, attributes: nil, relationships: relationships))
    }

    /// `POST /v1/<type>` creating a resource under `parent`.
    static func create(
        type: String,
        attributes: [String: AppInformationAPIValue],
        parent relationship: String,
        parentType: String,
        parentID: String
    ) -> AppInformationWriteDocument {
        let parent = Relationship(data: Identifier(type: parentType, id: parentID))
        return AppInformationWriteDocument(data: Resource(type: type, id: nil, attributes: attributes, relationships: [relationship: parent]))
    }

    func attribute(_ name: String) -> AppInformationAPIValue? {
        data.attributes?[name]
    }

    /// The related resource's ID; nil when it's absent or `null`.
    func relationshipID(_ name: String) -> String? {
        data.relationships?[name]?.data?.id
    }

    /// Whether the document sets this relationship (to a resource or `null`).
    func setsRelationship(_ name: String) -> Bool {
        data.relationships?[name] != nil
    }

    /// Sorted keys, so the same change always encodes to the same bytes.
    func encoded() -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return (try? encoder.encode(self)) ?? Data()
    }

    /// The document in a queued request's body, if it is one.
    static func decode(_ body: Data?) -> AppInformationWriteDocument? {
        guard let body else { return nil }
        return try? JSONDecoder().decode(AppInformationWriteDocument.self, from: body)
    }
}
