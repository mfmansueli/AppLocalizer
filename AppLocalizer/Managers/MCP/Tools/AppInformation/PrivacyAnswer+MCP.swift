//
//  PrivacyAnswer+MCP.swift
//  AppLocalizer
//

import Foundation

extension PrivacyAnswer {
    /// `{collected, purposes, linked, tracking}` with purpose ids.
    var mcpJSON: [String: JSONValue] {
        [
            "collected": .bool(collected),
            "purposes": .array(sortedPurposes.map { .string($0.rawValue) }),
            "linked": .bool(linked),
            "tracking": .bool(tracking),
        ]
    }
}
