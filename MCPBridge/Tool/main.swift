//
//  main.swift
//  applocalizer-mcp
//

import Foundation

// The stdio bridge in AppLocalizer.app/Contents/MacOS that Claude Desktop and
// Codex launch: JSON-RPC lines on stdin go to AppLocalizer's local MCP server
// with the pairing token, and its replies come back on stdout. Diagnostics go
// to stderr, which clients keep in their logs.

func writeLine(_ line: String, to handle: FileHandle) {
    handle.write(Data((line + "\n").utf8))
}

let options: MCPBridgeOptions
do {
    options = try MCPBridgeOptions(arguments: Array(CommandLine.arguments.dropFirst()))
} catch .help {
    writeLine(MCPBridgeOptions.usage, to: .standardOutput)
    exit(EXIT_SUCCESS)
} catch {
    writeLine(error.message, to: .standardError)
    exit(64) // EX_USAGE
}

let bridge = MCPBridge(options: options, transport: URLSession(configuration: .ephemeral)) { message in
    writeLine("applocalizer-mcp: \(message)", to: .standardError)
}

do {
    for try await line in FileHandle.standardInput.bytes.lines where !line.isEmpty {
        for reply in await bridge.forward(line) {
            writeLine(reply, to: .standardOutput)
        }
    }
} catch {
    writeLine("applocalizer-mcp: stdin closed: \(error.localizedDescription)", to: .standardError)
}

await bridge.close()
