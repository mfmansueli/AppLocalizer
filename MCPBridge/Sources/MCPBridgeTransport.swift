//
//  MCPBridgeTransport.swift
//  applocalizer-mcp
//

import Foundation

/// Sends the bridge's HTTP requests: `URLSession` in the tool, a fake in
/// tests.
protocol MCPBridgeTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}
