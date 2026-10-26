//
//  ConflictCheck.swift
//  AppLocalizer
//

import Foundation

/// How Review & Push notices that a value changed in App Store Connect since
/// it was fetched: before pushing, it `GET`s `path` and reads the string at
/// `keyPath` in the JSON response. When that differs from `expected`, the
/// change is shown as a conflict with both values instead of being pushed.
struct ConflictCheck: Hashable, Codable, Sendable {
    /// Path under `https://api.appstoreconnect.apple.com`, with any query.
    var path: String
    /// Keys into the response, array indices as numbers, e.g.
    /// `["data", "attributes", "subtitle"]` or `["included", "0", "attributes", "customerPrice"]`.
    var keyPath: [String]
    /// The value at the last fetch; nil when it was empty.
    var expected: String?
    var format: ConflictValueFormat = .text

    /// The value at `keyPath` in a JSON response, as a string; nil when it's
    /// missing, null or empty.
    func value(in data: Data) -> String? {
        guard var node = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) else { return nil }
        for key in keyPath {
            if let object = node as? [String: Any], let next = object[key] {
                node = next
            } else if let array = node as? [Any], let index = Int(key), array.indices.contains(index) {
                node = array[index]
            } else {
                return nil
            }
        }
        let value: String? = switch node {
        case let string as String: string
        case let number as NSNumber: number.stringValue
        default: nil
        }
        return value?.isEmpty == true ? nil : value
    }

    /// Whether `actual` differs from what was fetched. Numbers compare by
    /// value, so "199.9" and "199.90" match.
    func differs(from actual: String?) -> Bool {
        if let lhs = expected.flatMap(Self.number), let rhs = actual.flatMap(Self.number) {
            return lhs != rhs
        }
        return expected != actual
    }

    private static func number(_ text: String) -> Decimal? {
        guard text.allSatisfy({ $0.isNumber || $0 == "." || $0 == "-" }) else { return nil }
        return Decimal(string: text, locale: Locale(identifier: "en_US_POSIX"))
    }
}
