//
//  TemplateOperation.swift
//  AppLocalizer
//

import Foundation

/// One change to a template, as a proposal carries it:
/// `{ "op": "replace", "path": "caption.headline.size", "value": 104 }`.
/// Paths are dotted template paths; a slot's own value is
/// `slots.<i>.layout` or `slots.<i>.over.<path>` (a `null` value removes
/// the override), and `fonts.fallback.<script>` takes `null` for none.
struct TemplateOperation: Codable, Hashable, Sendable {
    /// `op` in JSON; only "replace" is supported.
    var operation: String
    var path: String
    var value: JSONValue

    enum CodingKeys: String, CodingKey {
        case operation = "op"
        case path, value
    }

    static let replaceOperation = "replace"

    init(operation: String = Self.replaceOperation, path: String, value: JSONValue) {
        self.operation = operation
        self.path = path
        self.value = value
    }

    static func replace(_ path: String, with value: JSONValue) -> TemplateOperation {
        TemplateOperation(path: path, value: value)
    }
}
