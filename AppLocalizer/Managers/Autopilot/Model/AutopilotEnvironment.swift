//
//  AutopilotEnvironment.swift
//  AppLocalizer
//

import Foundation

/// What the assistant reported about this Mac, for the sheet's footer:
/// "Xcode 26.1 · iPhone 17 Pro Max and iPad Pro 13″ simulators".
struct AutopilotEnvironment: Codable, Hashable, Sendable {
    var xcode: String?
    var simulators: [String] = []

    var summary: String? {
        var parts: [String] = []
        if let xcode, !xcode.isEmpty { parts.append(xcode.lowercased().hasPrefix("xcode") ? xcode : "Xcode \(xcode)") }
        if !simulators.isEmpty { parts.append(String(localized: "\(simulators.formatted(.list(type: .and))) simulators")) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
