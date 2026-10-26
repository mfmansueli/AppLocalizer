//
//  PrivacyEvidence.swift
//  AppLocalizer
//

import Foundation

/// One piece of evidence behind an assistant's App Privacy answer: an SDK,
/// its version and the manifest entry, or a file and line with a short
/// excerpt.
struct PrivacyEvidence: Hashable, Codable, Sendable {
    var kind: PrivacyEvidenceKind
    var sdk: String?
    var version: String?
    /// The manifest key, e.g. `NSPrivacyCollectedDataTypePurchaseHistory`,
    /// or a dependency file.
    var entry: String?
    var path: String?
    var line: Int?
    /// e.g. `try await Purchases.shared.purchase(package: package)`.
    var excerpt: String?

    /// "RevenueCat 5.14.2 · NSPrivacyCollectedDataTypePurchaseHistory" or
    /// "Lumen/Paywall/PaywallModel.swift:88".
    var reference: String {
        let sdkName = [sdk, version].compactMap(\.self).joined(separator: " ")
        let file = path.map { path in line.map { "\(path):\($0)" } ?? path }
        return [sdkName.isEmpty ? nil : sdkName, file, entry].compactMap(\.self).joined(separator: " · ")
    }

    /// "RevenueCat 5.14.2", for the cross-check's warning.
    var sdkName: String? {
        sdk.map { sdk in version.map { "\(sdk) \($0)" } ?? sdk }
    }

    /// The data type an SDK manifest entry declares as collected, for the
    /// cross-check.
    var declaredType: PrivacyDataType? {
        guard kind == .sdkManifest, let entry else { return nil }
        return PrivacyDataType.matching(entry)
    }
}
