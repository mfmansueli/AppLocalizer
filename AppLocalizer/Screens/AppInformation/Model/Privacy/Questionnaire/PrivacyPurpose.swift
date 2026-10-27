//
//  PrivacyPurpose.swift
//  AppLocalizer
//

import Foundation

/// Why a collected data type is used: Apple's six purposes, in App Store
/// Connect's order. The raw value is the key assistants and fastlane use.
enum PrivacyPurpose: String, CaseIterable, Identifiable, Hashable, Codable, Comparable, Sendable {
    case thirdPartyAdvertising = "THIRD_PARTY_ADVERTISING"
    case developersAdvertising = "DEVELOPERS_ADVERTISING"
    case analytics = "ANALYTICS"
    case productPersonalization = "PRODUCT_PERSONALIZATION"
    case appFunctionality = "APP_FUNCTIONALITY"
    case otherPurposes = "OTHER_PURPOSES"

    var id: String { rawValue }

    /// Apple's name, e.g. "Developer’s Advertising or Marketing".
    var title: String {
        switch self {
        case .thirdPartyAdvertising: String(localized: "Third-Party Advertising")
        case .developersAdvertising: String(localized: "Developer’s Advertising or Marketing")
        case .analytics: String(localized: "Analytics")
        case .productPersonalization: String(localized: "Product Personalization")
        case .appFunctionality: String(localized: "App Functionality")
        case .otherPurposes: String(localized: "Other Purposes")
        }
    }

    /// The toggle's label in a data-type row, e.g. "Your ads & marketing".
    var shortTitle: String {
        switch self {
        case .thirdPartyAdvertising: String(localized: "Third-party ads")
        case .developersAdvertising: String(localized: "Your ads & marketing")
        case .analytics: String(localized: "Analytics")
        case .productPersonalization: String(localized: "Personalization")
        case .appFunctionality: String(localized: "App functionality")
        case .otherPurposes: String(localized: "Other")
        }
    }

    private var order: Int { Self.allCases.firstIndex(of: self) ?? 0 }

    static func < (lhs: PrivacyPurpose, rhs: PrivacyPurpose) -> Bool {
        lhs.order < rhs.order
    }

    // MARK: - Matching

    /// The purpose an assistant or a file means: the key, Apple's name or a
    /// privacy manifest's `NSPrivacyCollectedDataTypePurpose…`, ignoring
    /// case, spaces and `_`. Nil for anything else, e.g. "SUPPORT".
    static func matching(_ text: String) -> PrivacyPurpose? {
        let wanted = normalized(text).replacing("nsprivacycollecteddatatypepurpose", with: "")
        return allCases.first { purpose in
            [purpose.rawValue, purpose.title, purpose.manifestSuffix].contains { normalized($0) == wanted }
        }
    }

    /// The closest of the six to a purpose that isn't one, for the refusal's
    /// "Did you mean …?".
    static func closest(to text: String) -> PrivacyPurpose {
        let wanted = normalized(text)
        if wanted.contains("third") || wanted.contains("partner") { return .thirdPartyAdvertising }
        if wanted.contains("market") || wanted.contains("advert") || wanted.contains("promo") { return .developersAdvertising }
        if wanted.contains("analytic") || wanted.contains("measure") || wanted.contains("metric") { return .analytics }
        if wanted.contains("personal") || wanted.contains("recommend") { return .productPersonalization }
        return .appFunctionality
    }

    private var manifestSuffix: String {
        switch self {
        case .thirdPartyAdvertising: "ThirdPartyAdvertising"
        case .developersAdvertising: "DevelopersAdvertising"
        case .analytics: "Analytics"
        case .productPersonalization: "ProductPersonalization"
        case .appFunctionality: "AppFunctionality"
        case .otherPurposes: "Other"
        }
    }

    private static func normalized(_ text: String) -> String {
        text.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
