//
//  JSONRPCResponse.swift
//  AppLocalizer
//

import Foundation

/// The server's answer to one request: a result or an error, never both.
struct JSONRPCResponse: Encodable, Hashable, Sendable {
    /// The request's id; null when the request couldn't even be read.
    var id: JSONValue
    var outcome: Outcome

    enum Outcome: Hashable, Sendable {
        case result(JSONValue)
        case error(JSONRPCError)
    }

    static func result(_ result: JSONValue, id: JSONValue) -> JSONRPCResponse {
        JSONRPCResponse(id: id, outcome: .result(result))
    }

    static func error(_ error: JSONRPCError, id: JSONValue = .null) -> JSONRPCResponse {
        JSONRPCResponse(id: id, outcome: .error(error))
    }

    private enum CodingKeys: String, CodingKey {
        case jsonrpc
        case id
        case result
        case error
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("2.0", forKey: .jsonrpc)
        try container.encode(id, forKey: .id)
        switch outcome {
        case let .result(result): try container.encode(result, forKey: .result)
        case let .error(error): try container.encode(error, forKey: .error)
        }
    }
}
