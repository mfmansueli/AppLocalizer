//
//  JSONRPCError.swift
//  AppLocalizer
//

import Foundation

/// A JSON-RPC error object. Tool failures aren't these: a tool that runs and
/// refuses answers with a result marked `isError`, so the assistant reads
/// the reason; these are for messages the server can't process at all.
struct JSONRPCError: Error, Codable, Hashable, Sendable {
    var code: Int
    var message: String
    var data: JSONValue?

    static let parseError = JSONRPCError(code: -32700, message: "Parse error: the body isn’t valid JSON.")

    static func invalidRequest(_ message: String) -> JSONRPCError {
        JSONRPCError(code: -32600, message: message)
    }

    static func methodNotFound(_ method: String) -> JSONRPCError {
        JSONRPCError(code: -32601, message: "Method not found: \(method)")
    }

    static func invalidParams(_ message: String) -> JSONRPCError {
        JSONRPCError(code: -32602, message: message)
    }

    static func internalError(_ message: String) -> JSONRPCError {
        JSONRPCError(code: -32603, message: message)
    }
}
