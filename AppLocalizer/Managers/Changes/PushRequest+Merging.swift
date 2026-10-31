//
//  PushRequest+Merging.swift
//  AppLocalizer
//

import Foundation

// Resources App Store Connect only takes whole. An age rating declaration
// that isn't fully answered rejects a `PATCH` that leaves any question out
// ("ENTITY_ERROR.ATTRIBUTE.REQUIRED — You must provide a value for the
// attribute 'ageAssurance'"), so a push sends every queued answer of one
// declaration in a single `PATCH` rather than one per question.
extension PushRequest {
    /// The resource types whose `PATCH`es go out together.
    static let wholeResourceTypes: Set<String> = ["ageRatingDeclarations"]

    /// For a `PATCH` of a resource App Store Connect only takes whole, its
    /// path: the requests that share it are sent as one.
    var mergeKey: String? {
        guard method == .patch else { return nil }
        let components = path.split(separator: "/")
        guard components.count == 3, Self.wholeResourceTypes.contains(String(components[1])) else { return nil }
        return path
    }

    /// One `PATCH` with every request's attributes and relationships, later
    /// ones winning; nil unless they're all JSON:API `PATCH`es of the same
    /// resource.
    static func merged(_ requests: [PushRequest]) -> PushRequest? {
        guard let first = requests.first, first.method == .patch,
              requests.allSatisfy({ $0.method == .patch && $0.path == first.path })
        else { return nil }
        var documents: [[String: Any]] = []
        for request in requests {
            guard let body = request.body,
                  let document = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  document["data"] is [String: Any]
            else { return nil }
            documents.append(document)
        }
        var merged = documents[0]
        var data = merged["data"] as? [String: Any] ?? [:]
        for document in documents.dropFirst() {
            guard let next = document["data"] as? [String: Any], next["type"] as? String == data["type"] as? String,
                  next["id"] as? String == data["id"] as? String
            else { return nil }
            for member in ["attributes", "relationships"] {
                guard let values = next[member] as? [String: Any] else { continue }
                data[member] = (data[member] as? [String: Any] ?? [:]).merging(values) { _, new in new }
            }
        }
        merged["data"] = data
        guard let body = try? JSONSerialization.data(withJSONObject: merged, options: [.sortedKeys]) else { return nil }
        return PushRequest(method: .patch, path: first.path, body: body)
    }
}
