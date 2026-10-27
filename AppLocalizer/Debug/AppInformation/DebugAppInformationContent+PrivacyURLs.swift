//
//  DebugAppInformationContent+PrivacyURLs.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

// The privacy URLs as App Store Connect would return them. Lumen Journal
// has every App Store locale on the app info Store Page edits, so a policy
// URL edit here is the same change as in Store Page; French (Canada),
// Hebrew and Hindi have no Privacy Policy URL, and every third locale has a
// User Privacy Choices URL.
extension DebugAppInformationContent {
    static let privacyPolicyURL = "https://lumen.example/privacy"
    static let privacyChoicesURL = "https://lumen.example/privacy/choices"

    static func privacyURLs(for app: StoreApp) -> PrivacyURLsContent {
        guard app.id == DebugFixtures.AppID.lumen else {
            let locales = [StoreLocale.englishUS, .german, .french, .japanese].map { locale in
                PrivacyURLsLocale(locale: locale, localizationID: "\(app.id)-info-\(locale.code)", policyURL: privacyPolicyURL)
            }
            return PrivacyURLsContent(appInfoID: "\(app.id)-info", primaryLocale: .englishUS, locales: locales)
        }
        let missing: Set<StoreLocale> = [.frenchCanada, .hebrew, .hindi]
        let locales = StoreLocaleCatalog.all.enumerated().map { index, locale in
            PrivacyURLsLocale(
                locale: locale,
                localizationID: "\(DebugStorePageContent.appInfoID)-\(locale.code)",
                policyURL: missing.contains(locale) ? "" : privacyPolicyURL,
                choicesURL: index.isMultiple(of: 3) ? privacyChoicesURL : ""
            )
        }
        return PrivacyURLsContent(appInfoID: DebugStorePageContent.appInfoID, primaryLocale: .englishUS, locales: locales)
    }
}
#endif
