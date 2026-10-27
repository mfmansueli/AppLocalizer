//
//  AppInfoLocalizationAttributes.swift
//  AppLocalizer
//

import Foundation

/// An `appInfoLocalizations` resource: one locale's app-level texts, shared
/// by every version.
struct AppInfoLocalizationAttributes: Decodable, Sendable {
    var locale: String
    var name: String?
    var subtitle: String?
    var privacyPolicyUrl: String?

    /// The texts by listing field, empty ones left out.
    var texts: [ListingField: String] {
        let values: [ListingField: String?] = [.name: name, .subtitle: subtitle, .privacyPolicyURL: privacyPolicyUrl]
        return values.compactMapValues { $0?.isEmpty == false ? $0 : nil }
    }
}
