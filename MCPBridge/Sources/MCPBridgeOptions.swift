//
//  MCPBridgeOptions.swift
//  applocalizer-mcp
//

import Foundation

/// `applocalizer-mcp --token <token> [--url <url>]`: the token Settings → AI
/// Assistants handed out when the assistant was paired, and the endpoint,
/// which stays on this Mac.
struct MCPBridgeOptions: Equatable, Sendable {
    /// Why the arguments can't be used.
    enum Problem: Error, Equatable {
        case help
        case missingToken
        case missingValue(String)
        case unknownArgument(String)
        case notLoopback(String)

        var message: String {
            switch self {
            case .help: MCPBridgeOptions.usage
            case .missingToken: "Missing --token. Pair the assistant in AppLocalizer → Settings → AI Assistants to get one.\n\(MCPBridgeOptions.usage)"
            case let .missingValue(name): "\(name) needs a value.\n\(MCPBridgeOptions.usage)"
            case let .unknownArgument(argument): "Unknown argument \(argument).\n\(MCPBridgeOptions.usage)"
            case let .notLoopback(url): "\(url) isn’t on this Mac; the token only goes to http://127.0.0.1 or localhost."
            }
        }
    }

    /// AppLocalizer's endpoint (`MCPEndpoint.url(port: MCPEndpoint.defaultPort)` in the app).
    static let defaultURL = URL(string: "http://127.0.0.1:47321/mcp")!

    static let usage = """
    Usage: applocalizer-mcp --token <token> [--url \(defaultURL.absoluteString)]
    Forwards an MCP client's stdio to AppLocalizer's local MCP server, which must be on.
    """

    var token: String
    var url: URL

    init(token: String, url: URL = defaultURL) {
        self.token = token
        self.url = url
    }

    /// The command-line arguments, without the program name.
    init(arguments: [String]) throws(Problem) {
        var token: String?
        var url = Self.defaultURL
        var remaining = arguments[...]
        while let argument = remaining.popFirst() {
            switch argument {
            case "-h", "--help":
                throw .help
            case "--token", "--url":
                guard let value = remaining.popFirst(), !value.isEmpty, !value.hasPrefix("--") else { throw .missingValue(argument) }
                if argument == "--token" {
                    token = value
                } else {
                    guard let parsed = URL(string: value), parsed.scheme == "http", Self.isLoopback(parsed.host()) else {
                        throw .notLoopback(value)
                    }
                    url = parsed
                }
            default:
                throw .unknownArgument(argument)
            }
        }
        guard let token else { throw .missingToken }
        self.init(token: token, url: url)
    }

    private static func isLoopback(_ host: String?) -> Bool {
        guard let host else { return false }
        return ["127.0.0.1", "localhost", "::1"].contains(host.lowercased())
    }
}
