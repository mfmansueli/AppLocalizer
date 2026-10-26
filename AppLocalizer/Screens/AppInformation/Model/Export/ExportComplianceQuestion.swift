//
//  ExportComplianceQuestion.swift
//  AppLocalizer
//

import Foundation

/// The export compliance questions App Store Connect asks for a build.
enum ExportComplianceQuestion: String, CaseIterable, Identifiable, Hashable, Codable, CodingKeyRepresentable, Sendable {
    case usesEncryption
    case isExempt
    case proprietary
    case thirdParty
    case availableInFrance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .usesEncryption: String(localized: "Does the app use encryption?")
        case .isExempt: String(localized: "Is all of it exempt?")
        case .proprietary: String(localized: "Proprietary or non-standard algorithms?")
        case .thirdParty: String(localized: "Third-party encryption, such as OpenSSL?")
        case .availableInFrance: String(localized: "Is the app available on the App Store in France?")
        }
    }

    var subtitle: String? {
        switch self {
        case .isExempt: String(localized: "Only encryption built into Apple’s operating systems: HTTPS, CryptoKit, the Keychain")
        default: nil
        }
    }
}
