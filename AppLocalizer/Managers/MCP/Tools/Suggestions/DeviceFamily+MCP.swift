//
//  DeviceFamily+MCP.swift
//  AppLocalizer
//

import Foundation

extension DeviceFamily {
    /// The `device` of an Accessibility suggestion: `iphone`, `ipad`,
    /// `watch`, `vision`, `mac` or `tv`.
    var mcpName: String {
        switch self {
        case .iPhone: "iphone"
        case .iPad: "ipad"
        case .appleWatch: "watch"
        case .vision: "vision"
        case .mac: "mac"
        case .appleTV: "tv"
        }
    }

    /// The device an assistant named: its MCP name, App Store Connect's
    /// (`APPLE_WATCH`) or its name ("Apple Watch"), ignoring case.
    init?(mcpName name: String) {
        let wanted = name.lowercased().filter(\.isLetter)
        let aliases: [String: DeviceFamily] = ["applewatch": .appleWatch, "applevisionpro": .vision, "visionpro": .vision, "appletv": .appleTV]
        if let family = aliases[wanted] ?? Self.allCases.first(where: { [$0.mcpName, $0.rawValue.lowercased().filter(\.isLetter)].contains(wanted) }) {
            self = family
        } else {
            return nil
        }
    }
}
