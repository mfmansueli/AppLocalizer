//
//  StorePageViewModel+AcceptAll.swift
//  AppLocalizer
//

import Foundation

// The language bar and the App Store preview: how many suggestions wait in
// each language, Accept n in this language, and Accept All Languages, which
// shows them first unless the person said not to.
extension StorePageViewModel {
    // MARK: - Reading

    /// The language bar, once a language is open.
    func languageBarModel(acceptsRightAway: Bool) -> LanguageBarModel? {
        guard let current = editorLocale else { return nil }
        let entries = editorLocales.map { locale in
            LanguageBarEntry(
                locale: locale,
                count: visibleSuggestions(in: locale).count,
                comingCount: comingCount(in: locale),
                isNewPage: isNewLanguage(locale)
            )
        }
        return LanguageBarModel(entries: entries, current: current, acceptsRightAway: acceptsRightAway)
    }

    /// What Accept All Languages offers, the open language first in focus.
    func acceptAllSelection() -> AcceptAllSelection {
        let groups = editorLocales.compactMap { locale -> AcceptAllGroup? in
            let items = visibleSuggestions(in: locale).compactMap { suggestion -> AcceptAllItem? in
                guard let (field, _) = storeField(of: suggestion) else { return nil }
                return AcceptAllItem(
                    id: suggestion.id,
                    title: field.title,
                    source: suggestion.source,
                    current: value(field, in: locale),
                    suggested: suggestion.value,
                    reason: suggestion.reason
                )
            }
            guard !items.isEmpty else { return nil }
            return AcceptAllGroup(
                id: locale.code,
                title: locale.name,
                regionCode: locale.regionCode,
                isNewPage: isNewLanguage(locale),
                isRightToLeft: locale.isRTL,
                items: items
            )
        }
        return AcceptAllSelection(kind: .storePage, groups: groups, focus: editorLocale?.code)
    }

    /// The page in `locale`: what's in the fields, or with Suggested, the
    /// suggestions waiting on top of it.
    func previewModel(in locale: StoreLocale, showsSuggested: Bool) -> AppStorePreviewModel {
        func text(_ field: ListingField) -> AppStorePreviewText {
            if showsSuggested, let suggestion = shownSuggestion(field, in: locale) {
                return AppStorePreviewText(value: suggestion.value, isSuggested: true)
            }
            return AppStorePreviewText(value: value(field, in: locale))
        }
        return AppStorePreviewModel(
            locale: locale,
            name: text(.name),
            subtitle: text(.subtitle),
            promotionalText: text(.promotionalText),
            description: text(.description),
            whatsNew: text(.whatsNew),
            versionString: content?.version.versionString ?? ""
        )
    }

    // MARK: - Accepting

    /// The language bar's button: right away when the person said not to
    /// ask, otherwise the sheet.
    func acceptAllLanguages(withoutAsking: Bool) {
        guard withoutAsking else {
            sheet = .acceptAll
            return
        }
        let batch = editorLocales.flatMap { visibleSuggestions(in: $0) }
        accept(batch, toast: AcceptAllKind.storePage.acceptedText(batch.count, groups: languageCount(of: batch), withoutAsking: true))
    }

    /// The sheet's Accept: only what was left ticked.
    func acceptSuggestions(ids: Set<String>, turnedOffAsking: Bool) {
        let batch = editorLocales.flatMap { visibleSuggestions(in: $0) }.filter { ids.contains($0.id) }
        accept(batch, toast: AcceptAllKind.storePage.acceptedText(batch.count, groups: languageCount(of: batch), turnedOffAsking: turnedOffAsking))
    }

    private func languageCount(of batch: [FieldSuggestion]) -> Int {
        Set(batch.compactMap { storeField(of: $0)?.1 }).count
    }
}
