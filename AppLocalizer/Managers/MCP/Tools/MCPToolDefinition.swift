//
//  MCPToolDefinition.swift
//  AppLocalizer
//

import Foundation

/// How a tool presents itself in `tools/list`: its name, what it does, the
/// JSON Schema of its arguments, and which switch (if any) gates it.
struct MCPToolDefinition: Hashable, Sendable {
    var name: String
    var title: String
    var description: String
    /// A JSON Schema object for the arguments.
    var inputSchema: JSONValue
    /// nil for tools that only read.
    var proposalKind: MCPProposalKind?

    var isReadOnly: Bool { proposalKind == nil }

    /// The entry in a `tools/list` result.
    var json: JSONValue {
        [
            "name": .string(name),
            "title": .string(title),
            "description": .string(description),
            "inputSchema": inputSchema,
            "annotations": [
                "title": .string(title),
                "readOnlyHint": .bool(isReadOnly),
                // Proposals only queue changes for review; nothing is destroyed.
                "destructiveHint": false,
                "idempotentHint": true,
                "openWorldHint": false,
            ],
        ]
    }

    /// An object schema with these properties, `required` naming the
    /// mandatory ones.
    static func schema(_ properties: [String: JSONValue] = [:], required: [String] = []) -> JSONValue {
        [
            "type": "object",
            "properties": .object(properties),
            "required": .array(required.map(JSONValue.string)),
            "additionalProperties": false,
        ]
    }

    /// A string property with a description.
    static func string(_ description: String) -> JSONValue {
        ["type": "string", "description": .string(description)]
    }
}
