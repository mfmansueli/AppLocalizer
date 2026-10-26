//
//  PushRequest+Placeholders.swift
//  AppLocalizer
//

import Foundation

// Values a request can only have when it's sent, written into its path or
// body as placeholders and filled in by the push:
//
// - `{createdID}`: the ID App Store Connect gave the resource that an
//   earlier `POST` of the same change created, e.g. publishing an
//   accessibility declaration that the change's first request creates.
// - `{secret:<name>}`: a secret kept in the Keychain (`SecretStore`), so the
//   queue's file and the push history never hold it, e.g. App Review's demo
//   account password. It sits inside a JSON string and is escaped for it.
extension PushRequest {
    static let createdIDPlaceholder = "{createdID}"

    static func secretPlaceholder(named name: String) -> String {
        "{secret:\(name)}"
    }

    /// The secrets the body refers to, by name, in order.
    var secretNames: [String] {
        guard let text = body.flatMap({ String(data: $0, encoding: .utf8) }) else { return [] }
        var names: [String] = []
        var rest = text[...]
        while let start = rest.range(of: "{secret:"), let end = rest[start.upperBound...].firstIndex(of: "}") {
            names.append(String(rest[start.upperBound..<end]))
            rest = rest[rest.index(after: end)...]
        }
        return names
    }

    /// Whether the path or body waits for an earlier `POST`'s ID.
    var needsCreatedID: Bool {
        path.contains(Self.createdIDPlaceholder) || bodyText?.contains(Self.createdIDPlaceholder) == true
    }

    /// The request as it's sent: placeholders replaced by the created ID and
    /// the named secrets. Throws when one of them isn't available.
    func resolved(createdID: String?, secret: (String) throws -> String?) throws -> PushRequest {
        let names = secretNames
        guard needsCreatedID || !names.isEmpty else { return self }
        var resolved = self
        var text = bodyText
        if needsCreatedID {
            guard let createdID else { throw PushRequestPlaceholderError.missingCreatedID }
            resolved.path = path.replacingOccurrences(of: Self.createdIDPlaceholder, with: createdID)
            text = text?.replacingOccurrences(of: Self.createdIDPlaceholder, with: createdID)
        }
        for name in names {
            guard let value = try secret(name) else { throw PushRequestPlaceholderError.missingSecret(name) }
            text = text?.replacingOccurrences(of: Self.secretPlaceholder(named: name), with: Self.jsonStringContent(value))
        }
        resolved.body = text.map { Data($0.utf8) }
        return resolved
    }

    private var bodyText: String? {
        body.flatMap { String(data: $0, encoding: .utf8) }
    }

    /// `value` escaped for the inside of a JSON string literal.
    private static func jsonStringContent(_ value: String) -> String {
        guard let data = try? JSONEncoder().encode(value), let quoted = String(data: data, encoding: .utf8) else { return value }
        return String(quoted.dropFirst().dropLast())
    }
}
