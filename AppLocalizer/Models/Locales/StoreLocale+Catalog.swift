//
//  StoreLocale+Catalog.swift
//  AppLocalizer
//

import Foundation

// The 39 App Store locales, named as App Store Connect names them.
//
// Flag regions that aren't in the code: Catalan → Andorra (its only
// official language, and it avoids picking Spain over Catalonia);
// Chinese (Traditional) → Hong Kong (renders everywhere, unlike the Taiwan
// flag on Macs set to mainland China); Arabic → Saudi Arabia, as in `ar-SA`.
//
// Translation identifiers: Norwegian is `nb` (Bokmål, what App Store
// Connect's `no` means); Spanish (Mexico) stays `es-MX` so providers can
// pick Latin American Spanish.
extension StoreLocale {
    static let arabic = StoreLocale("ar-SA", "Arabic", region: "SA", language: "ar", isRTL: true)
    static let catalan = StoreLocale("ca", "Catalan", region: "AD", language: "ca")
    static let chineseSimplified = StoreLocale("zh-Hans", "Chinese (Simplified)", region: "CN", language: "zh-Hans")
    static let chineseTraditional = StoreLocale("zh-Hant", "Chinese (Traditional)", region: "HK", language: "zh-Hant")
    static let croatian = StoreLocale("hr", "Croatian", region: "HR", language: "hr")
    static let czech = StoreLocale("cs", "Czech", region: "CZ", language: "cs")
    static let danish = StoreLocale("da", "Danish", region: "DK", language: "da")
    static let dutch = StoreLocale("nl-NL", "Dutch", region: "NL", language: "nl")
    static let englishAustralia = StoreLocale("en-AU", "English (Australia)", region: "AU", language: "en-AU")
    static let englishCanada = StoreLocale("en-CA", "English (Canada)", region: "CA", language: "en-CA")
    static let englishUK = StoreLocale("en-GB", "English (U.K.)", region: "GB", language: "en-GB")
    static let englishUS = StoreLocale("en-US", "English (U.S.)", region: "US", language: "en-US")
    static let finnish = StoreLocale("fi", "Finnish", region: "FI", language: "fi")
    static let french = StoreLocale("fr-FR", "French", region: "FR", language: "fr")
    static let frenchCanada = StoreLocale("fr-CA", "French (Canada)", region: "CA", language: "fr-CA")
    static let german = StoreLocale("de-DE", "German", region: "DE", language: "de")
    static let greek = StoreLocale("el", "Greek", region: "GR", language: "el")
    static let hebrew = StoreLocale("he", "Hebrew", region: "IL", language: "he", isRTL: true)
    static let hindi = StoreLocale("hi", "Hindi", region: "IN", language: "hi")
    static let hungarian = StoreLocale("hu", "Hungarian", region: "HU", language: "hu")
    static let indonesian = StoreLocale("id", "Indonesian", region: "ID", language: "id")
    static let italian = StoreLocale("it", "Italian", region: "IT", language: "it")
    static let japanese = StoreLocale("ja", "Japanese", region: "JP", language: "ja")
    static let korean = StoreLocale("ko", "Korean", region: "KR", language: "ko")
    static let malay = StoreLocale("ms", "Malay", region: "MY", language: "ms")
    static let norwegian = StoreLocale("no", "Norwegian", region: "NO", language: "nb")
    static let polish = StoreLocale("pl", "Polish", region: "PL", language: "pl")
    static let portugueseBrazil = StoreLocale("pt-BR", "Portuguese (Brazil)", region: "BR", language: "pt-BR")
    static let portuguesePortugal = StoreLocale("pt-PT", "Portuguese (Portugal)", region: "PT", language: "pt-PT")
    static let romanian = StoreLocale("ro", "Romanian", region: "RO", language: "ro")
    static let russian = StoreLocale("ru", "Russian", region: "RU", language: "ru")
    static let slovak = StoreLocale("sk", "Slovak", region: "SK", language: "sk")
    static let spanishMexico = StoreLocale("es-MX", "Spanish (Mexico)", region: "MX", language: "es-MX")
    static let spanishSpain = StoreLocale("es-ES", "Spanish (Spain)", region: "ES", language: "es-ES")
    static let swedish = StoreLocale("sv", "Swedish", region: "SE", language: "sv")
    static let thai = StoreLocale("th", "Thai", region: "TH", language: "th")
    static let turkish = StoreLocale("tr", "Turkish", region: "TR", language: "tr")
    static let ukrainian = StoreLocale("uk", "Ukrainian", region: "UA", language: "uk")
    static let vietnamese = StoreLocale("vi", "Vietnamese", region: "VN", language: "vi")
}
