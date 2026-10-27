//
//  AccessibilityAnswer.swift
//  AppLocalizer
//

import Foundation

/// What a declaration says for one device family: whether the app supports
/// any of the features, and which. App Store Connect stores No as every
/// `supports…` false.
struct AccessibilityAnswer: Hashable, Codable, Sendable {
    var features: Set<AccessibilityFeature>

    init(features: Set<AccessibilityFeature> = []) {
        self.features = features
    }

    /// Reads the `supports…` booleans of a response or a queued write.
    init(supports: [String: Bool]) {
        features = Set(AccessibilityFeature.allCases.filter { supports[$0.apiKey] == true })
    }

    /// "Supports accessibility features: Yes".
    var supportsAny: Bool { !features.isEmpty }

    /// The features in Apple's order.
    var orderedFeatures: [AccessibilityFeature] {
        AccessibilityFeature.allCases.filter(features.contains)
    }

    /// "6 features: VoiceOver, Voice Control, …", "Doesn’t indicate support".
    var summary: String {
        guard supportsAny else { return String(localized: "Doesn’t indicate support") }
        let names = orderedFeatures.map(\.name).joined(separator: ", ")
        return features.count == 1 ? String(localized: "1 feature: \(names)") : String(localized: "\(features.count) features: \(names)")
    }

    /// The `supports…` attributes of a write: every feature of the family,
    /// true or false.
    func attributes(for family: DeviceFamily) -> [String: AppInformationAPIValue] {
        Dictionary(uniqueKeysWithValues: family.features.map { ($0.apiKey, AppInformationAPIValue.bool(features.contains($0))) })
    }
}
