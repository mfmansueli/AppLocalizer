//
//  StorePageSampleData.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// DEBUG-only: the designer's "Lumen Journal" store page, for DEBUG scenes,
/// previews and tests. The texts are the prototype's, verbatim (the
/// `+Texts`, `+MachineTranslations`, `+InAppTexts` and `+Import` files are
/// generated from it).
///
/// `listing` matches the coverage screenshot: "10 of 39 locales · 11
/// missing · 1 over the limit · 1 machine-translated · 1 not pushed".
enum StorePageSampleData {
    static let appName = "Lumen Journal"
    static let assistantClient = "Claude Code"

    /// Editable.
    static let editableVersion = ListingVersion("1.4", state: .prepareForSubmission)
    /// Live and read-only.
    static let liveVersion = ListingVersion("1.3", state: .readyForDistribution)
    static let versions = [editableVersion, liveVersion]

    /// The ten locales the app has, in the order they were added.
    static let presentLocales: [StoreLocale] = [
        .englishUS, .englishUK, .german, .french, .spanishSpain, .spanishMexico, .portugueseBrazil, .italian, .japanese, .arabic,
    ]

    /// The locales the translation scenes add before translating.
    static let addedLocales: [StoreLocale] = [.korean, .chineseSimplified, .dutch]

    /// The Translate sheet's "Don't translate" terms and tone.
    static let glossary = TranslationGlossary(terms: ["Lumen", "Lumen Plus", "Face ID", "iCloud"], tone: .warmAndSimple)

    /// Settings → Translation's glossary, which also has "Weekly Reflections".
    static let settingsGlossary = TranslationGlossary(
        terms: ["Lumen", "Lumen Plus", "Face ID", "iCloud", "Weekly Reflections"],
        tone: .warmAndSimple
    )

    /// Version 1.4 as fetched: nothing pending; Japanese keywords were
    /// pushed machine-translated and nobody has reviewed them.
    static let fetchedListing = StoreListing(
        appName: appName,
        version: editableVersion,
        primaryLocale: .englishUS,
        locales: presentLocales.map { locale in
            LocaleListing(locale: locale, remote: remoteTexts[locale] ?? [:], machineTranslated: locale == .japanese ? [.keywords] : [])
        }
    )

    /// The coverage screenshot: on top of `fetchedListing`, the German
    /// subtitle was edited past the limit (31/30) and the French promotional
    /// text was edited.
    static let listing: StoreListing = {
        var listing = fetchedListing
        listing.edit(.subtitle, in: .german, to: "Private Notizen, sanfte Impulse")
        listing.edit(
            .promotionalText,
            in: .french,
            to: "Nouveau : vos bilans hebdomadaires réunissent vos plus beaux moments sur une page apaisée."
        )
        return listing
    }()

    /// Version 1.3, live and read-only: the same texts with 1.3's What's
    /// New. Its app-level fields stay editable ("No editable version").
    static let liveListing = StoreListing(
        appName: appName,
        version: liveVersion,
        primaryLocale: .englishUS,
        locales: presentLocales.map { locale in
            var texts = remoteTexts[locale] ?? [:]
            texts[.whatsNew] = locale == .englishUS ? liveWhatsNew : nil
            return LocaleListing(locale: locale, remote: texts)
        }
    )

    /// What the sample translator returns for an item: the prototype's
    /// translation when it has one, the source text for copies (URLs,
    /// English variants), or nil, which the prototype skips.
    static func translation(for item: TranslationItem) -> String? {
        if let text = machineTranslations[item.key.locale]?[item.key.field] { return text }
        return item.method == .copy ? item.sourceText : nil
    }
}
#endif
