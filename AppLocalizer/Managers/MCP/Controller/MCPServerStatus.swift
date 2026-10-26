//
//  MCPServerStatus.swift
//  AppLocalizer
//

import Foundation

/// Where the server's socket is.
enum MCPServerStatus: Equatable, Sendable {
    case off
    case starting
    case listening(port: UInt16)
    case failed(message: String)
}
