//
//  KeychainError.swift
//  AppLocalizer
//

import Foundation
import Security

/// A failed `SecItem…` call, described with the Security framework's message.
struct KeychainError: LocalizedError, Equatable {
    let status: OSStatus

    var errorDescription: String? {
        let reason = SecCopyErrorMessageString(status, nil) as String? ?? "OSStatus \(status)"
        return String(localized: "The Keychain couldn't store the API key: \(reason)")
    }
}
