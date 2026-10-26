//
//  AccessibilityURLValidator.swift
//  AppLocalizer
//

import Foundation

/// Checks the Accessibility URL: optional, but when set, a full https
/// address with a host.
enum AccessibilityURLValidator {
    /// Why the text can't be pushed, or nil when it's empty or valid.
    static func problem(in text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        if let components = URLComponents(string: trimmed), components.scheme?.lowercased() == "https",
           let host = components.host, host.contains("."), !trimmed.contains(" ")
        {
            return nil
        }
        return String(localized: "Enter a full https address, like https://example.com/accessibility.")
    }
}
