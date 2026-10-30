//
//  KeyAssistantConfiguration.swift
//  AppLocalizer
//

import Foundation

/// An API key set up for suggestions: the vendor and model, what each
/// request may include besides App Store Connect's text, and whether
/// Settings → Translation uses the same key. The key itself is in the
/// Keychain; only its last four characters are kept here, to show it.
struct KeyAssistantConfiguration: Hashable, Codable, Sendable {
    var vendor: AIProviderVendor
    var model: KeyAssistantModel
    var keySuffix: String
    /// Commit messages since the last release tag, and CHANGELOG.md.
    var readsProjectFolder = false
    /// "~/Developer/Lumen".
    var projectFolderPath: String?
    /// A security-scoped bookmark, so the folder can be read after a
    /// relaunch.
    var projectFolderBookmark: Data?
    /// The app's latest App Store reviews.
    var readsReviews = false
    var usesKeyForTranslations = false

    /// "sk-ant-…x7Qa".
    var maskedKey: String {
        "\(vendor.keyPrefix.prefix(7))…\(keySuffix)"
    }
}
