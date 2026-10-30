//
//  StorePageBuiltInSuggestions.swift
//  AppLocalizer
//

import Foundation

/// The Store Page's built-in checks, run on the listing as it's shown
/// (App Store Connect's texts with pending changes on top). They need
/// nothing else, so suggestions work from day one:
/// - Keywords that repeat words of the name or subtitle, repeat each other,
///   or waste bytes on spaces: "Optimize" as a suggestion.
/// - An empty URL that other languages fill: the primary language's, or
///   the address most of the others use. An empty marketing URL in the
///   primary language gets the site the others link to.
enum StorePageBuiltInSuggestions {
    static func suggestions(for listing: StoreListing, appID: StoreApp.ID) -> [FieldSuggestion] {
        listing.displayLocales.flatMap { locale in
            [keywords(in: locale, listing: listing, appID: appID)]
                + [ListingField.privacyPolicyURL, .supportURL, .marketingURL].map { emptyURL($0, in: locale, listing: listing, appID: appID) }
        }
        .compactMap(\.self)
    }

    // MARK: - Keywords

    private static func keywords(in locale: StoreLocale, listing: StoreListing, appID: StoreApp.ID) -> FieldSuggestion? {
        guard listing.canEdit(.keywords) else { return nil }
        let analysis = KeywordAnalysis(
            keywords: listing.value(.keywords, in: locale),
            name: listing.value(.name, in: locale),
            subtitle: listing.value(.subtitle, in: locale)
        )
        guard analysis.canOptimize, !analysis.optimized.isEmpty else { return nil }
        return .builtIn(appID: appID, target: .storePage(locale, .keywords), value: analysis.optimized, reason: keywordsReason(analysis))
    }

    /// "Removes “journal” and “mood”. They’re already in the name and
    /// subtitle, which App Store search uses too."
    static func keywordsReason(_ analysis: KeywordAnalysis) -> String {
        let covered = analysis.tokens.filter { $0.state == .inNameOrSubtitle }.map { "“\($0.text)”" }
        let repeated = analysis.tokens.filter { $0.state == .duplicate }.map { "“\($0.text)”" }
        var sentences: [String] = []
        if covered.count == 1, let word = covered.first {
            sentences.append(String(localized: "Removes \(word). It’s already in the name or subtitle, which App Store search uses too."))
        } else if !covered.isEmpty {
            let words = covered.formatted(.list(type: .and))
            sentences.append(String(localized: "Removes \(words). They’re already in the name and subtitle, which App Store search uses too."))
        }
        if !repeated.isEmpty {
            let words = repeated.formatted(.list(type: .and))
            sentences.append(covered.isEmpty
                ? String(localized: "Removes \(words), which you listed twice.")
                : String(localized: "Also drops \(words), listed twice."))
        }
        if analysis.wastedSpaceBytes > 0 {
            sentences.append(sentences.isEmpty
                ? String(localized: "Removes the spaces around commas. App Store Connect counts them as bytes.")
                : String(localized: "Spaces around commas go too."))
        }
        return sentences.joined(separator: " ")
    }

    // MARK: - URLs

    private static func emptyURL(_ field: ListingField, in locale: StoreLocale, listing: StoreListing, appID: StoreApp.ID) -> FieldSuggestion? {
        guard listing.canEdit(field), listing.value(field, in: locale).trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        let others = listing.displayLocales.filter { $0 != locale }.compactMap { other -> (StoreLocale, String)? in
            let value = listing.value(field, in: other).trimmingCharacters(in: .whitespaces)
            return ListingFieldValidator.isValidURL(value) ? (other, value) : nil
        }
        guard !others.isEmpty else { return nil }
        let target = SuggestionTarget.storePage(locale, field)
        let primary = listing.primaryLocale

        if locale != primary, let fromPrimary = others.first(where: { $0.0 == primary }) {
            let reason = String(localized: "Empty in \(locale.name). \(primary.name) uses this address.")
            return .builtIn(appID: appID, target: target, value: fromPrimary.1, reason: reason)
        }
        if field == .marketingURL, let site = mostCommon(others.compactMap { host(of: $0.1) }) {
            let linking = others.filter { host(of: $0.1) == site }.map(\.0)
            let support = host(of: listing.value(.supportURL, in: locale)) == site
            let names = languageList(linking)
            let reason = support
                ? String(localized: "Empty in \(locale.name). \(names) link to \(site), and so does your support URL.")
                : String(localized: "Empty in \(locale.name). \(names) link to \(site).")
            return .builtIn(appID: appID, target: target, value: "https://\(site)", reason: reason)
        }
        guard let value = mostCommon(others.map(\.1)) else { return nil }
        let names = languageList(others.filter { $0.1 == value }.map(\.0))
        return .builtIn(appID: appID, target: target, value: value, reason: String(localized: "Empty in \(locale.name). \(names) use this address."))
    }

    /// `lumen.example` for `https://lumen.example/de`.
    private static func host(of url: String) -> String? {
        URLComponents(string: url.trimmingCharacters(in: .whitespaces))?.host?.lowercased()
    }

    /// The most frequent value, the first one on a tie.
    private static func mostCommon(_ values: [String]) -> String? {
        let counts = Dictionary(values.map { ($0, 1) }, uniquingKeysWith: +)
        let highest = counts.values.max()
        return values.first { counts[$0] == highest }
    }

    /// "German and Japanese", or "German, French and 4 other languages".
    private static func languageList(_ locales: [StoreLocale]) -> String {
        let names = locales.map(\.name)
        guard names.count > 3 else { return names.formatted(.list(type: .and)) }
        return String(localized: "\(names[0]), \(names[1]) and \(names.count - 2) other languages")
    }
}
