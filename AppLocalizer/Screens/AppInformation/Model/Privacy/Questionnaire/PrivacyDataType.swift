//
//  PrivacyDataType.swift
//  AppLocalizer
//

import Foundation

/// One of the 35 data types of App Store Connect's App Privacy
/// questionnaire, with Apple's exact names, in App Store Connect's order.
/// The raw value is the id assistants use; `matching(_:)` also takes
/// fastlane's keys and privacy-manifest keys.
enum PrivacyDataType: String, CaseIterable, Identifiable, Hashable, Codable, CodingKeyRepresentable, Sendable {
    case name
    case email
    case phone
    case address
    case otherContact
    case health
    case fitness
    case payment
    case credit
    case otherFinancial
    case preciseLocation
    case coarseLocation
    case sensitive
    case contacts
    case emails
    case photos
    case audio
    case gameplay
    case support
    case otherContent
    case browsing
    case search
    case userId
    case deviceId
    case purchases
    case interaction
    case advertising
    case otherUsage
    case crash
    case performance
    case otherDiagnostics
    case environment
    case hands
    case head
    case otherTypes

    var id: String { rawValue }

    /// Apple's name, e.g. "Purchase History".
    var name: String {
        switch self {
        case .name: String(localized: "Name")
        case .email: String(localized: "Email Address")
        case .phone: String(localized: "Phone Number")
        case .address: String(localized: "Physical Address")
        case .otherContact: String(localized: "Other User Contact Info")
        case .health: String(localized: "Health")
        case .fitness: String(localized: "Fitness")
        case .payment: String(localized: "Payment Info")
        case .credit: String(localized: "Credit Info")
        case .otherFinancial: String(localized: "Other Financial Info")
        case .preciseLocation: String(localized: "Precise Location")
        case .coarseLocation: String(localized: "Coarse Location")
        case .sensitive: String(localized: "Sensitive Info")
        case .contacts: String(localized: "Contacts")
        case .emails: String(localized: "Emails or Text Messages")
        case .photos: String(localized: "Photos or Videos")
        case .audio: String(localized: "Audio Data")
        case .gameplay: String(localized: "Gameplay Content")
        case .support: String(localized: "Customer Support")
        case .otherContent: String(localized: "Other User Content")
        case .browsing: String(localized: "Browsing History")
        case .search: String(localized: "Search History")
        case .userId: String(localized: "User ID")
        case .deviceId: String(localized: "Device ID")
        case .purchases: String(localized: "Purchase History")
        case .interaction: String(localized: "Product Interaction")
        case .advertising: String(localized: "Advertising Data")
        case .otherUsage: String(localized: "Other Usage Data")
        case .crash: String(localized: "Crash Data")
        case .performance: String(localized: "Performance Data")
        case .otherDiagnostics: String(localized: "Other Diagnostic Data")
        case .environment: String(localized: "Environment Scanning")
        case .hands: String(localized: "Hands")
        case .head: String(localized: "Head")
        case .otherTypes: String(localized: "Other Data Types")
        }
    }

    var category: PrivacyDataCategory {
        switch self {
        case .name, .email, .phone, .address, .otherContact: .contactInfo
        case .health, .fitness: .healthAndFitness
        case .payment, .credit, .otherFinancial: .financialInfo
        case .preciseLocation, .coarseLocation: .location
        case .sensitive: .sensitiveInfo
        case .contacts: .contacts
        case .emails, .photos, .audio, .gameplay, .support, .otherContent: .userContent
        case .browsing: .browsingHistory
        case .search: .searchHistory
        case .userId, .deviceId: .identifiers
        case .purchases: .purchases
        case .interaction, .advertising, .otherUsage: .usageData
        case .crash, .performance, .otherDiagnostics: .diagnostics
        case .environment: .surroundings
        case .hands, .head: .body
        case .otherTypes: .otherData
        }
    }

    /// fastlane's `app_privacy_details.json` category, e.g. `PURCHASE_HISTORY`.
    var fastlaneKey: String {
        switch self {
        case .name: "NAME"
        case .email: "EMAIL_ADDRESS"
        case .phone: "PHONE_NUMBER"
        case .address: "PHYSICAL_ADDRESS"
        case .otherContact: "OTHER_CONTACT_INFO"
        case .health: "HEALTH"
        case .fitness: "FITNESS"
        case .payment: "PAYMENT_INFORMATION"
        case .credit: "CREDIT_AND_FRAUD"
        case .otherFinancial: "OTHER_FINANCIAL_INFO"
        case .preciseLocation: "PRECISE_LOCATION"
        case .coarseLocation: "COARSE_LOCATION"
        case .sensitive: "SENSITIVE_INFO"
        case .contacts: "CONTACTS"
        case .emails: "EMAILS_OR_TEXT_MESSAGES"
        case .photos: "PHOTOS_OR_VIDEOS"
        case .audio: "AUDIO"
        case .gameplay: "GAMEPLAY_CONTENT"
        case .support: "CUSTOMER_SUPPORT"
        case .otherContent: "OTHER_USER_CONTENT"
        case .browsing: "BROWSING_HISTORY"
        case .search: "SEARCH_HISTORY"
        case .userId: "USER_ID"
        case .deviceId: "DEVICE_ID"
        case .purchases: "PURCHASE_HISTORY"
        case .interaction: "PRODUCT_INTERACTION"
        case .advertising: "ADVERTISING_DATA"
        case .otherUsage: "OTHER_USAGE_DATA"
        case .crash: "CRASH_DATA"
        case .performance: "PERFORMANCE_DATA"
        case .otherDiagnostics: "OTHER_DIAGNOSTIC_DATA"
        case .environment: "ENVIRONMENT_SCANNING"
        case .hands: "HANDS"
        case .head: "HEAD"
        case .otherTypes: "OTHER_DATA"
        }
    }

    /// The `NSPrivacyCollectedDataType` key an SDK's privacy manifest uses,
    /// e.g. `NSPrivacyCollectedDataTypePurchaseHistory`.
    var manifestKey: String {
        "NSPrivacyCollectedDataType" + manifestSuffix
    }

    /// Apple's spelling, including `PhotosorVideos`.
    private var manifestSuffix: String {
        switch self {
        case .name: "Name"
        case .email: "EmailAddress"
        case .phone: "PhoneNumber"
        case .address: "PhysicalAddress"
        case .otherContact: "OtherUserContactInfo"
        case .health: "Health"
        case .fitness: "Fitness"
        case .payment: "PaymentInfo"
        case .credit: "CreditInfo"
        case .otherFinancial: "OtherFinancialInfo"
        case .preciseLocation: "PreciseLocation"
        case .coarseLocation: "CoarseLocation"
        case .sensitive: "SensitiveInfo"
        case .contacts: "Contacts"
        case .emails: "EmailsOrTextMessages"
        case .photos: "PhotosorVideos"
        case .audio: "AudioData"
        case .gameplay: "GameplayContent"
        case .support: "CustomerSupport"
        case .otherContent: "OtherUserContent"
        case .browsing: "BrowsingHistory"
        case .search: "SearchHistory"
        case .userId: "UserID"
        case .deviceId: "DeviceID"
        case .purchases: "PurchaseHistory"
        case .interaction: "ProductInteraction"
        case .advertising: "AdvertisingData"
        case .otherUsage: "OtherUsageData"
        case .crash: "CrashData"
        case .performance: "PerformanceData"
        case .otherDiagnostics: "OtherDiagnosticData"
        case .environment: "EnvironmentScanning"
        case .hands: "Hands"
        case .head: "Head"
        case .otherTypes: "OtherDataTypes"
        }
    }

    // MARK: - Matching

    /// The type an assistant or a file means: the id, fastlane's key or the
    /// manifest key, ignoring case, spaces and `_`. Nil when nothing matches.
    static func matching(_ text: String) -> PrivacyDataType? {
        let wanted = normalized(text)
        return allCases.first { type in
            [type.rawValue, type.fastlaneKey, type.manifestKey, type.manifestSuffix].contains { normalized($0) == wanted }
        }
    }

    private static func normalized(_ text: String) -> String {
        text.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
