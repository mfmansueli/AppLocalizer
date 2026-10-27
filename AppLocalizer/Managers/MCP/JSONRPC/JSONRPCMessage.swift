//
//  JSONRPCMessage.swift
//  AppLocalizer
//

import Foundation

/// A JSON-RPC 2.0 message from an MCP client: a request (method and id), a
/// notification (method, no id) or a response to a request the server sent
/// (id with a result or an error).
struct JSONRPCMessage: Decodable, Hashable, Sendable {
    var jsonrpc: String
    var id: JSONValue?
    var method: String?
    var params: JSONValue?
    var result: JSONValue?
    var error: JSONRPCError?

    init(id: JSONValue? = nil, method: String? = nil, params: JSONValue? = nil, result: JSONValue? = nil, error: JSONRPCError? = nil) {
        jsonrpc = "2.0"
        self.id = id
        self.method = method
        self.params = params
        self.result = result
        self.error = error
    }

    enum Kind: Equatable {
        case request
        case notification
        case response
    }

    var kind: Kind? {
        guard jsonrpc == "2.0" else { return nil }
        if method != nil { return id == nil ? .notification : .request }
        return id != nil && (result != nil || error != nil) ? .response : nil
    }
}
