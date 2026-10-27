//
//  PrivacyURLsContent.swift
//  AppLocalizer
//

import Foundation

/// The Privacy URLs tab's data from App Store Connect: the app info being
/// prepared (else the live one) and each locale's Privacy Policy URL and
/// User Privacy Choices URL.
struct PrivacyURLsContent: Hashable, Sendable {
    var appInfoID: String
    var primaryLocale: StoreLocale
    /// By English name, as App Store Connect lists them.
    var locales: [PrivacyURLsLocale]

    init(appInfoID: String, primaryLocale: StoreLocale, locales: [PrivacyURLsLocale]) {
        self.appInfoID = appInfoID
        self.primaryLocale = primaryLocale
        self.locales = locales.sorted { $0.locale.name.localizedStandardCompare($1.locale.name) == .orderedAscending }
    }

    func remote(_ locale: StoreLocale) -> PrivacyURLsLocale? {
        locales.first { $0.locale == locale }
    }
}
