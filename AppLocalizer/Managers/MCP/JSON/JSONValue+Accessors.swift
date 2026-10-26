//
//  JSONValue+Accessors.swift
//  AppLocalizer
//

import Foundation

extension JSONValue {
    /// The member named `key` of an object; nil for other values.
    subscript(key: String) -> JSONValue? {
        objectValue?[key]
    }

    var stringValue: String? {
        if case let .string(value) = self { return value }
        return nil
    }

    /// Whole numbers only; `2.0` counts, `2.5` doesn't.
    var intValue: Int? {
        switch self {
        case let .int(value): value
        case let .double(value) where value.rounded() == value: Int(exactly: value)
        default: nil
        }
    }

    var doubleValue: Double? {
        switch self {
        case let .int(value): Double(value)
        case let .double(value): value
        default: nil
        }
    }

    var boolValue: Bool? {
        if case let .bool(value) = self { return value }
        return nil
    }

    var arrayValue: [JSONValue]? {
        if case let .array(value) = self { return value }
        return nil
    }

    var objectValue: [String: JSONValue]? {
        if case let .object(value) = self { return value }
        return nil
    }

    var isNull: Bool { self == .null }

    /// Any `Encodable` value as JSON, e.g. a tool's result.
    init(encoding value: some Encodable) throws {
        let data = try JSONEncoder().encode(value)
        self = try JSONDecoder().decode(JSONValue.self, from: data)
    }

    /// Compact JSON text with sorted keys, for a tool result's text content.
    func jsonString() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(self), let text = String(bytes: data, encoding: .utf8) else { return "null" }
        return text
    }
}
