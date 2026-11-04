//
//  AutopilotArtworkSize+MCP.swift
//  AppLocalizer
//

import Foundation

/// What the assistant designs, by name, in the MCP texts.
extension AutopilotArtworkSize {
    /// "the header and search", "the header", "the search results image",
    /// "the one 16:9 image".
    var mcpPlaces: String {
        switch self {
        case .headerAndSearch: "the header and search"
        case .headerOnly: "the header"
        case .searchOnly: "the search results image"
        case .wide: "the one 16:9 image"
        }
    }
}
