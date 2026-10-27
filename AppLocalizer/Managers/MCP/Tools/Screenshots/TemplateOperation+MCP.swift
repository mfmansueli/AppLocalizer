//
//  TemplateOperation+MCP.swift
//  AppLocalizer
//

import Foundation

extension TemplateOperation {
    /// Operations as an assistant sends them: a list of
    /// `{op, path, value}`, or for a patch, an object of path → value.
    static func mcpOperations(from value: JSONValue, argument: String) throws -> [TemplateOperation] {
        if let object = value.objectValue {
            return object.keys.sorted().map { TemplateOperation.replace($0, with: object[$0] ?? .null) }
        }
        guard let items = value.arrayValue else {
            throw MCPToolError.invalidArgument(name: argument, expected: String(localized: "a list of {op, path, value}"))
        }
        return try items.map { item in
            guard let path = item["path"]?.stringValue, let value = item["value"] else {
                throw MCPToolError.invalidArgument(name: argument, expected: String(localized: "a list of {op, path, value}"))
            }
            return TemplateOperation(operation: item["op"]?.stringValue ?? replaceOperation, path: path, value: value)
        }
    }
}
