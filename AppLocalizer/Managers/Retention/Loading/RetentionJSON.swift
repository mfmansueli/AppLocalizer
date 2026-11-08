//
//  RetentionJSON.swift
//  AppLocalizer
//

import Foundation

/// Reading App Store Connect's JSON:API documents for retention: a
/// resource's attributes and relationships, and every page of a list
/// with what it included.
enum RetentionJSON {
    static func object(_ data: Data) -> [String: Any]? {
        try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    /// A single-resource response's `data` type and ID.
    static func resource(in data: Data) -> (type: String, id: String)? {
        guard let resource = object(data)?["data"] as? [String: Any],
              let type = resource["type"] as? String, let id = resource["id"] as? String
        else { return nil }
        return (type, id)
    }

    static func attributes(of resource: [String: Any]) -> [String: Any] {
        resource["attributes"] as? [String: Any] ?? [:]
    }

    static func string(_ key: String, of resource: [String: Any]) -> String? {
        attributes(of: resource)[key] as? String
    }

    static func int(_ key: String, of resource: [String: Any]) -> Int? {
        (attributes(of: resource)[key] as? NSNumber)?.intValue
    }

    /// `relationships.<name>.data.id` of a to-one relationship.
    static func relatedID(_ name: String, of resource: [String: Any]) -> String? {
        let relationship = (resource["relationships"] as? [String: Any])?[name] as? [String: Any]
        return (relationship?["data"] as? [String: Any])?["id"] as? String
    }

    /// The IDs in a to-many relationship's `data`.
    static func relatedIDs(_ name: String, of resource: [String: Any]) -> [String] {
        let relationship = (resource["relationships"] as? [String: Any])?[name] as? [String: Any]
        return (relationship?["data"] as? [[String: Any]] ?? []).compactMap { $0["id"] as? String }
    }

    /// A price string such as "2.49" as a decimal.
    static func decimal(_ text: String?) -> Decimal? {
        text.flatMap { Decimal(string: $0, locale: Locale(identifier: "en_US_POSIX")) }
    }

    /// Every page's `data` and `included`, following `links.next`; `note`
    /// gets each response's rate limit.
    @MainActor
    static func resources(
        at path: String,
        via transport: any PushTransport,
        note: (AppStoreConnectRateLimit?) -> Void = { _ in }
    ) async throws -> (data: [[String: Any]], included: [[String: Any]]) {
        var next: String? = path
        var data: [[String: Any]] = []
        var included: [[String: Any]] = []
        while let page = next {
            let response = try await transport.fetch(page)
            note(response.rateLimit)
            let document = object(response.data)
            if let list = document?["data"] as? [[String: Any]] {
                data += list
            } else if let single = document?["data"] as? [String: Any] {
                data.append(single)
            }
            included += document?["included"] as? [[String: Any]] ?? []
            next = (document?["links"] as? [String: Any])?["next"] as? String
        }
        return (data, included)
    }
}
