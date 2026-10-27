//
//  PrivacyURLsLocale.swift
//  AppLocalizer
//

import Foundation

/// One locale's privacy URLs as App Store Connect has them, on its
/// `appInfoLocalizations` resource.
struct PrivacyURLsLocale: Identifiable, Hashable, Sendable {
    var locale: StoreLocale
    var localizationID: String
    var policyURL = ""
    var choicesURL = ""

    var id: String { locale.code }
}
