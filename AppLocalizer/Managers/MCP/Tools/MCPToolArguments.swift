//
//  MCPToolArguments.swift
//  AppLocalizer
//

import Foundation

/// A tool call's arguments, read with the checks a tool needs: each getter
/// throws `MCPToolError.invalidArgument` naming the argument, so the
/// assistant can fix its call.
struct MCPToolArguments: Hashable, Sendable {
    var values: [String: JSONValue]

    init(_ values: [String: JSONValue] = [:]) {
        self.values = values
    }

    func string(_ name: String) throws -> String {
        guard let value = try optionalString(name) else { throw MCPToolError.invalidArgument(name: name, expected: String(localized: "a string")) }
        return value
    }

    /// nil when absent, null or empty.
    func optionalString(_ name: String) throws -> String? {
        guard let value = values[name], !value.isNull else { return nil }
        guard let string = value.stringValue else { throw MCPToolError.invalidArgument(name: name, expected: String(localized: "a string")) }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Accepts a list of strings or a single string.
    func optionalStrings(_ name: String) throws -> [String]? {
        guard let value = values[name], !value.isNull else { return nil }
        if let single = value.stringValue { return [single] }
        guard let strings = value.arrayValue?.map(\.stringValue), !strings.contains(nil) else {
            throw MCPToolError.invalidArgument(name: name, expected: String(localized: "a list of strings"))
        }
        return strings.compactMap(\.self)
    }

    func array(_ name: String) throws -> [JSONValue] {
        guard let array = values[name]?.arrayValue else {
            throw MCPToolError.invalidArgument(name: name, expected: String(localized: "a list"))
        }
        return array
    }

    /// nil when absent or null.
    func optionalArray(_ name: String) throws -> [JSONValue]? {
        guard let value = values[name], !value.isNull else { return nil }
        guard let array = value.arrayValue else { throw MCPToolError.invalidArgument(name: name, expected: String(localized: "a list")) }
        return array
    }

    /// nil when absent or null.
    func optionalInt(_ name: String) throws -> Int? {
        guard let value = values[name], !value.isNull else { return nil }
        guard let int = value.intValue else { throw MCPToolError.invalidArgument(name: name, expected: String(localized: "a whole number")) }
        return int
    }

    /// nil when absent or null.
    func optionalBool(_ name: String) throws -> Bool? {
        guard let value = values[name], !value.isNull else { return nil }
        guard let bool = value.boolValue else { throw MCPToolError.invalidArgument(name: name, expected: String(localized: "true or false")) }
        return bool
    }

    func optionalObject(_ name: String) throws -> [String: JSONValue]? {
        guard let value = values[name], !value.isNull else { return nil }
        guard let object = value.objectValue else { throw MCPToolError.invalidArgument(name: name, expected: String(localized: "an object")) }
        return object
    }
}
