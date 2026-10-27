//
//  URLSession+MCPBridgeTransport.swift
//  applocalizer-mcp
//

import Foundation

extension URLSession: MCPBridgeTransport {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await data(for: request)
        guard let response = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (data, response)
    }
}
