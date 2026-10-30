//
//  AIProviderKeyStatus.swift
//  AppLocalizer
//

import Foundation

/// What Settings → Translation says under the AI provider's API key: no key
/// saved, the check running, connected, rejected by the vendor, or saved
/// but not checked (offline, a rate limit, the vendor down).
enum AIProviderKeyStatus: Equatable, Sendable {
    case notSaved
    case checking(AIProviderVendor)
    case connected(AIProviderKeyCheck)
    /// 401 or 403: the key is saved but the vendor won't take it.
    case rejected(AIProviderVendor)
    /// The key is saved, but the check got no answer about it.
    case unchecked(AIProviderVendor, reason: String)

    /// The status a failed check leaves.
    init(vendor: AIProviderVendor, error: any Error) {
        switch error {
        case AIProviderError.unauthorized: self = .rejected(vendor)
        case let error as URLError where Self.offlineCodes.contains(error.code):
            self = .unchecked(vendor, reason: String(localized: "You’re offline. Check again when this Mac is back online."))
        default: self = .unchecked(vendor, reason: error.localizedDescription)
        }
    }

    /// The line under the key field; nil with no key saved.
    var text: String? {
        switch self {
        case .notSaved: nil
        case let .checking(vendor): String(localized: "Saved · checking with \(vendor.title)…")
        case let .connected(check): String(localized: "Saved · connected to \(check.vendor.title) · \(check.milliseconds) ms")
        case let .rejected(vendor): String(localized: "Saved, but \(vendor.title) rejected this key")
        case let .unchecked(vendor, _): String(localized: "Saved · couldn’t check it with \(vendor.title)")
        }
    }

    /// More on the line, for its tooltip and VoiceOver.
    var detail: String? {
        switch self {
        case .notSaved: nil
        case .checking: String(localized: "Kept in this Mac’s Keychain.")
        case let .connected(check):
            String(localized: "Kept in this Mac’s Keychain. \(check.vendor.title) accepted it, so translations can use it.")
        case let .rejected(vendor):
            String(localized: "\(vendor.title) answered that the key is wrong, revoked or has no access. Paste a working key to replace it.")
        case let .unchecked(_, reason): reason
        }
    }

    /// Whether checking again could change the answer.
    var canCheckAgain: Bool {
        switch self {
        case .rejected, .unchecked: true
        case .notSaved, .checking, .connected: false
        }
    }

    private static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .timedOut, .dnsLookupFailed,
        .dataNotAllowed, .internationalRoamingOff,
    ]
}
