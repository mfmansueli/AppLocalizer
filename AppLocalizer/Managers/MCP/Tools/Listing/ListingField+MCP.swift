//
//  ListingField+MCP.swift
//  AppLocalizer
//

import Foundation

extension ListingField {
    /// The field an assistant named: App Store Connect's attribute name
    /// (`subtitle`, `whatsNew`, `privacyPolicyUrl`), ignoring case and `_`.
    static func matching(_ name: String) -> ListingField? {
        let wanted = name.replacingOccurrences(of: "_", with: "").lowercased()
        return allCases.first { $0.rawValue.lowercased() == wanted }
    }

    /// Every field name, for argument errors and schemas.
    static var mcpNames: [String] {
        allCases.map(\.rawValue)
    }

    /// `{"max": 30, "unit": "characters"}`, or null for URLs.
    var limitJSON: JSONValue {
        guard let limit else { return .null }
        return ["max": .int(limit.maximum), "unit": .string(limit.unit == .bytes ? "bytes" : "characters")]
    }
}
