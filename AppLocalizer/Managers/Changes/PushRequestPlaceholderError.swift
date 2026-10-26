//
//  PushRequestPlaceholderError.swift
//  AppLocalizer
//

import Foundation

/// Why a request's placeholders couldn't be filled in when it was sent
/// (`PushRequest+Placeholders.swift`). The push shows it on the change's
/// progress row, and the change stays queued.
enum PushRequestPlaceholderError: LocalizedError, Equatable {
    /// The request uses `{createdID}`, but no earlier `POST` of the change
    /// returned an ID.
    case missingCreatedID
    /// The named secret isn't in this Mac's Keychain any more.
    case missingSecret(String)

    var errorDescription: String? {
        switch self {
        case .missingCreatedID:
            String(localized: "App Store Connect didn't return the new resource's ID, so the next step couldn't be sent.")
        case .missingSecret:
            String(localized: "A password this change needs isn't in this Mac's Keychain any more. Enter it again.")
        }
    }
}
