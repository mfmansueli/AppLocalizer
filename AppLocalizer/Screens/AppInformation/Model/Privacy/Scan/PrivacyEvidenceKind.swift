//
//  PrivacyEvidenceKind.swift
//  AppLocalizer
//

import Foundation

/// Where a piece of App Privacy evidence comes from. The raw value is the
/// `kind` assistants send with `propose_privacy_answers`.
enum PrivacyEvidenceKind: String, CaseIterable, Identifiable, Hashable, Codable, Sendable {
    /// An entry in an SDK's `PrivacyInfo.xcprivacy`.
    case sdkManifest = "sdk_manifest"
    /// A package in Package.resolved, Podfile.lock or Cartfile.resolved.
    case dependency
    /// An Info.plist key, e.g. a usage description.
    case infoPlist = "info_plist"
    case entitlement
    /// A line of code: a request carrying user fields, a sign-up form, an
    /// analytics event, ATT or IDFA, a receipt sent to a backend.
    case code

    var id: String { rawValue }

    /// The evidence popover's small caps heading.
    var title: String {
        switch self {
        case .sdkManifest: String(localized: "SDK privacy manifest")
        case .dependency: String(localized: "Dependency")
        case .infoPlist: String(localized: "Info.plist")
        case .entitlement: String(localized: "Entitlements")
        case .code: String(localized: "Code")
        }
    }

    /// The kind an assistant means, ignoring case and `_`, so "sdkManifest"
    /// and "SDK_MANIFEST" both work.
    static func matching(_ text: String) -> PrivacyEvidenceKind? {
        let wanted = text.lowercased().filter(\.isLetter)
        if wanted == "entitlements" { return .entitlement }
        return allCases.first { $0.rawValue.filter(\.isLetter) == wanted }
    }
}
