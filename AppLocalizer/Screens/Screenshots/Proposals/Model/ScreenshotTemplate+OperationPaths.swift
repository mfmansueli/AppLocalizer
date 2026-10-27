//
//  ScreenshotTemplate+OperationPaths.swift
//  AppLocalizer
//

import Foundation

// Reading the value an operation's path points at, the way a proposal
// addresses it: schema paths, `slots.<i>.layout`, and
// `slots.<i>.over.<path>`, whose key is itself a dotted path.
extension ScreenshotTemplate {
    /// The value at an operation's path, or nil when nothing is set there
    /// (an override the slot doesn't have, an unset fallback).
    func operationValue(at path: String) -> JSONValue? {
        let parts = path.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard parts.first == "slots" else {
            let value = value(at: path)
            return value?.isNull == true ? nil : value
        }
        guard parts.count >= 3, let index = Int(parts[1]), slots.indices.contains(index) else { return nil }
        if parts.count == 3, parts[2] == "layout" { return .string(slots[index].layout.rawValue) }
        guard parts.count > 3, parts[2] == "over" else { return nil }
        return slots[index].over[parts[3...].joined(separator: ".")]
    }
}
