//
//  KeyAssistantKeyState.swift
//  AppLocalizer
//

import Foundation

/// Check Key's answer, under the key field.
enum KeyAssistantKeyState: Hashable, Sendable {
    /// Nothing checked yet: the field shows "Get a key from Anthropic ↗".
    case idle
    case checking
    /// "Key works · 3 models available".
    case works(String)
    /// "Anthropic rejected this key (401). Check that it was copied in full."
    case rejected(String)

    var isWorking: Bool {
        if case .works = self { return true }
        return false
    }
}
