//
//  MCPBridgeEventStream.swift
//  applocalizer-mcp
//

import Foundation

/// Reads a `text/event-stream` reply: each event's `data:` lines joined, one
/// JSON-RPC message per event.
enum MCPBridgeEventStream {
    static func messages(in body: Data) -> [String] {
        let text = (String(bytes: body, encoding: .utf8) ?? "").replacingOccurrences(of: "\r\n", with: "\n")
        return text.components(separatedBy: "\n\n").compactMap { event in
            let data = event.split(separator: "\n", omittingEmptySubsequences: false)
                .filter { $0.hasPrefix("data:") }
                .map { line in
                    let value = line.dropFirst("data:".count)
                    return value.hasPrefix(" ") ? String(value.dropFirst()) : String(value)
                }
            return data.isEmpty ? nil : data.joined(separator: "\n")
        }
    }
}
