//
//  KeyCheckFailure.swift
//  AppLocalizer
//

import Foundation

/// Why a key check failed, in the words Connect and Settings → Account
/// show: Apple rejected the key, its role is too low, the Mac is offline,
/// or something else with its own message.
enum KeyCheckFailure: Equatable, Sendable {
    /// 401: wrong key ID for the `.p8`, a revoked key, or a wrong issuer ID.
    case rejected
    /// 403: the role can't manage apps.
    case roleTooLow
    /// Nothing reached Apple.
    case offline
    case other(String)

    init(_ error: any Error) {
        switch error {
        case AppStoreConnectError.unauthorized: self = .rejected
        case AppStoreConnectError.forbidden: self = .roleTooLow
        case let error as URLError where Self.offlineCodes.contains(error.code): self = .offline
        default: self = .other(error.localizedDescription)
        }
    }

    var title: String {
        switch self {
        case .rejected: String(localized: "App Store Connect rejected this key (401).")
        case .roleTooLow: String(localized: "This key’s role can’t manage apps (403).")
        case .offline: String(localized: "You’re offline.")
        case .other: String(localized: "The key couldn’t be checked.")
        }
    }

    var message: String {
        switch self {
        case .rejected: String(localized: "Check that the Key ID matches the .p8 file and that the key hasn’t been revoked.")
        case .roleTooLow: String(localized: "Create a Team Key with the Admin or App Manager role, then connect again.")
        case .offline: String(localized: "Nothing was sent. Connect again when this Mac is back online.")
        case let .other(message): message
        }
    }

    private static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .timedOut, .dnsLookupFailed,
        .dataNotAllowed, .internationalRoamingOff,
    ]
}
