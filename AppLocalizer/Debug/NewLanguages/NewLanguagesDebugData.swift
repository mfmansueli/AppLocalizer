//
//  NewLanguagesDebugData.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Lumen Journal's project supports Polish, Turkish and Hebrew, which its
/// App Store page doesn't have (`DebugAppSupport`), and Claude Code drafted
/// each one's page: name, subtitle, promotional text, description, keywords
/// and What's New. The support and marketing URLs come from the built-in
/// checks when the Store Page loads.
@MainActor
enum NewLanguagesDebugData {
    static var appID: StoreApp.ID { DebugFixtures.AppID.lumen }
    static let languages: [StoreLocale] = [.polish, .turkish, .hebrew]

    /// The design's suggestions (`SuggestionsDebugData.store()`) with
    /// Claude Code's drafts of the three new pages.
    static func store() -> FieldSuggestionStore {
        let store = SuggestionsDebugData.store()
        for locale in languages {
            for (field, value) in drafts(for: locale) {
                store.add(
                    appID: appID,
                    target: .storePage(locale, field),
                    value: value,
                    reason: reason(for: field, in: locale),
                    source: .assistant(client: SuggestionsDebugData.client)
                )
            }
        }
        return store
    }

    /// The pending changes of Polish added with every draft accepted, and
    /// the URLs English (U.S.) has.
    static func polishChanges() -> [PendingChange] {
        let content = DebugStorePageContent.lumen(versionID: DebugStorePageContent.editableVersionID)
        var listing = content.listing()
        listing.addLocale(.polish)
        for (field, value) in drafts(for: .polish) {
            listing.update(field, in: .polish) { $0.acceptSuggestion(value, from: .assistant(client: SuggestionsDebugData.client)) }
        }
        for field in [ListingField.supportURL, .marketingURL] {
            let value = listing.value(field, in: .englishUS)
            guard !value.isEmpty else { continue }
            listing.update(field, in: .polish) { $0.acceptSuggestion(value, from: .builtInSuggestion) }
        }
        var builder = ListingChangeBuilder(appID: appID, ids: content.ids, versionString: content.version.versionString)
        builder.newPages = Set(languages)
        return builder.changes(for: listing)
    }

    /// Claude Code's draft of a new page, in the editor's order.
    static func drafts(for locale: StoreLocale) -> [(ListingField, String)] {
        let fields: [ListingField] = [.name, .subtitle, .promotionalText, .description, .keywords, .whatsNew]
        return Array(zip(fields, texts[locale.code] ?? []))
    }

    private static func reason(for field: ListingField, in locale: StoreLocale) -> String {
        switch field {
        case .keywords: "Translated search terms, not word-for-word: what people in this language search for."
        case .whatsNew: "Translated from the English What’s New suggestion."
        default: "Translated from English (U.S.) with your glossary; the app’s own \(locale.name) strings were the reference."
        }
    }

    private static let texts: [String: [String]] = [
        "pl": [
            "Lumen — Dziennik",
            "Dziennik nastroju i inspiracje",
            "Pisz codziennie choć trochę. Lumen chroni prywatność Twoich wpisów i synchronizuje je na wszystkich urządzeniach.",
            "Lumen to spokojne miejsce do pisania. Zapisz jedno zdanie lub całą stronę, śledź nastrój i wracaj do tego, co ważne.",
            "dziennik,pamiętnik,nastrój,wdzięczność,pisanie,nawyki,wspomnienia,planer",
            """
            • Cotygodniowe podsumowanie: spokojny przegląd tygodnia w każdą niedzielę
            • Szybsze wyszukiwanie we wpisach z wielu lat
            • Naprawiono synchronizację iCloud na starszych urządzeniach
            """,
        ],
        "tr": [
            "Lumen — Günlük",
            "Ruh hali günlüğü ve ilhamlar",
            "Her gün biraz yaz. Lumen yazdıklarını gizli tutar ve tüm cihazlarında eşitler.",
            "Lumen, yazmak için sakin bir yer. Bir satır ya da bir sayfa yaz, ruh halini takip et ve önemli olana geri dön.",
            "günlük,ruh hali,şükran,yazma,alışkanlık,anılar,planlayıcı",
            """
            • Haftalık değerlendirme: Her pazar haftanın sakin bir özeti
            • Yıllara yayılan kayıtlarda daha hızlı arama
            • Eski cihazlarda iCloud eşitleme sorunu giderildi
            """,
        ],
        "he": [
            "Lumen — יומן",
            "יומן מצב רוח והשראה",
            "כתבו קצת בכל יום. Lumen שומר על הפרטיות של הרשומות שלכם ומסנכרן אותן בכל המכשירים.",
            "Lumen הוא מקום שקט לכתיבה. כתבו שורה או עמוד שלם, עקבו אחרי מצב הרוח וחזרו למה שחשוב.",
            "יומן,מצב רוח,הכרת תודה,כתיבה,הרגלים,זיכרונות",
            """
            • סיכום שבועי: סקירה רגועה של השבוע בכל יום ראשון
            • חיפוש מהיר יותר ברשומות של שנים
            • תוקן סנכרון iCloud במכשירים ישנים
            """,
        ],
    ]
}
#endif
