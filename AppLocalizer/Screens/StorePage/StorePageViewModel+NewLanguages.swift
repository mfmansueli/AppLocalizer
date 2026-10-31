//
//  StorePageViewModel+NewLanguages.swift
//  AppLocalizer
//

import Foundation

// Languages the app supports that its App Store page doesn't have: the
// assistant reported the project's string catalogs (`AppSupportCenter`), and
// each language the App Store lacks is suggested as a new page. Adding one
// goes through the same new-locale changes as Add Locale; its page is created
// when you push, even before it has text.
extension StorePageViewModel {
    // MARK: - Reading the project

    /// What the app's Xcode project supports, as its assistant reported it.
    var appSupport: AppSupportCenter? { services.appSupport }

    /// The locales App Store Connect has for the version: the App Store page.
    var storeLocales: [StoreLocale] { content?.locales ?? [] }

    /// Every language the project has and the App Store page doesn't, said
    /// Not Now to or not, added here or not.
    var projectLocalesNotOnStore: Set<StoreLocale> {
        Set(missingProjectLanguages.compactMap(\.storeLocale))
    }

    /// The project's languages the App Store page doesn't have, in the
    /// project's order.
    private var missingProjectLanguages: [ProjectLanguage] {
        appSupport?.missingLanguages(for: app.id, storeLocales: storeLocales.map(\.code)) ?? []
    }

    /// The languages to suggest: in the project, not on the App Store, not
    /// added yet and not said Not Now to. Only while the version can change.
    var pendingLanguages: [ProjectLanguage] {
        guard isVersionEditable, let listing, let appSupport else { return [] }
        return appSupport.pendingLanguages(for: app.id, storeLocales: storeLocales.map(\.code)).filter { language in
            language.storeLocale.map { !listing.contains($0) } ?? false
        }
    }

    var pendingLocales: [StoreLocale] { pendingLanguages.compactMap(\.storeLocale) }

    func isPendingLanguage(_ locale: StoreLocale) -> Bool {
        pendingLocales.contains(locale)
    }

    /// A project language added as a new page that isn't pushed yet.
    func isAddedLanguage(_ locale: StoreLocale) -> Bool {
        listing?.contains(locale) == true && !storeLocales.contains(locale) && projectLocalesNotOnStore.contains(locale)
    }

    /// Not on the App Store yet: a language to suggest, or one added here
    /// (from the project or with Add Locale). The picker marks it New.
    func isNewLanguage(_ locale: StoreLocale) -> Bool {
        guard listing != nil, !storeLocales.contains(locale) else { return false }
        return isPendingLanguage(locale) || listing?.contains(locale) == true
    }

    /// Project languages added and not pushed, in the picker's order.
    var addedLanguages: [StoreLocale] {
        newEditorLocales.filter(isAddedLanguage)
    }

    /// The project language that becomes `locale`.
    func projectLanguage(for locale: StoreLocale) -> ProjectLanguage? {
        appSupport?.language(for: app.id, storeLocale: locale.code)
    }

    /// A project language's tab shows its fields even while they're all
    /// empty, with its suggestions; another empty locale says it has no
    /// text yet.
    func showsEmptyLocale(_ locale: StoreLocale) -> Bool {
        isEmptyLocale(locale) && !projectLocalesNotOnStore.contains(locale) && !isPendingLanguage(locale)
    }

    // MARK: - The picker

    /// The editor's languages: the App Store page's, primary first, then
    /// the new ones (added here or suggested from the project), in the
    /// project's order and then by name.
    var newEditorLocales: [StoreLocale] {
        guard let listing else { return [] }
        let order = (appSupport?.profile(for: app.id)?.languages ?? []).compactMap(\.storeLocale)
        let new = listing.displayLocales.filter { !storeLocales.contains($0) } + pendingLocales
        return new.sorted { lhs, rhs in
            let left = order.firstIndex(of: lhs) ?? .max
            let right = order.firstIndex(of: rhs) ?? .max
            if left != right { return left < right }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    // MARK: - Texts

    /// "Lumen Journal’s 1.4 build".
    private var buildName: String {
        guard let version = content?.version.versionString else { return String(localized: "\(app.name)’s build") }
        return String(localized: "\(app.name)’s \(version) build")
    }

    /// "English", as in "see the English page".
    private var primaryLanguageName: String {
        (listing?.primaryLocale ?? .englishUS).languageName
    }

    /// On an App Store language's tab: "Lumen Journal’s 1.4 build supports
    /// 3 more languages than its App Store page: Polish, Turkish, Hebrew.
    /// People who use them see the English page."
    var newLanguagesBannerText: String? {
        let names = pendingLocales.map(\.name)
        guard !names.isEmpty else { return nil }
        let list = names.joined(separator: ", ")
        if names.count == 1 {
            return String(localized: """
            \(buildName) supports 1 more language than its App Store page: \(list). People who use it see the \(primaryLanguageName) page.
            """)
        }
        return String(localized: """
        \(buildName) supports \(names.count) more languages than its App Store page: \(list). People who use them see the \
        \(primaryLanguageName) page.
        """)
    }

    /// "Add All 3", or "Add Polish" for one.
    var addAllLanguagesTitle: String {
        let pending = pendingLocales
        if pending.count == 1, let only = pending.first { return String(localized: "Add \(only.name)") }
        return String(localized: "Add All \(pending.count)")
    }

    /// On a suggested language's tab: "Polish isn’t on the App Store yet".
    func newLanguageTitle(_ locale: StoreLocale) -> String {
        String(localized: "\(locale.name) isn’t on the App Store yet")
    }

    /// "Lumen Journal’s 1.4 build is translated into Polish
    /// (Localizable.xcstrings: 412 of 418 strings (98%)). People who use
    /// Polish see the English page today. Claude Code drafted the page
    /// below."
    func newLanguageText(_ locale: StoreLocale) -> String {
        let evidence = projectLanguage(for: locale).map(inlineEvidence) ?? ""
        let drafted = drafter(of: locale).map { String(localized: "\($0) drafted the page below.") }
            ?? String(localized: "Connect an assistant or an AI provider to draft its text.")
        return String(localized: """
        \(buildName) is translated into \(locale.name)\(evidence). People who use \(locale.name) see the \(primaryLanguageName) page \
        today. \(drafted)
        """)
    }

    /// " (Localizable.xcstrings: 401 of 418 strings (96%); right to left;
    /// tested in LumenUITests)", or "" when the report says nothing more.
    private func inlineEvidence(_ language: ProjectLanguage) -> String {
        let source = appSupport?.profile(for: app.id)?.languageSource
        var parts = [[source, language.coverage].compactMap(\.self).joined(separator: ": ")]
        if let note = language.note, !note.isEmpty { parts.append(note.prefix(1).lowercased() + note.dropFirst()) }
        let text = parts.filter { !$0.isEmpty }.joined(separator: "; ")
        return text.isEmpty ? "" : " (\(text))"
    }

    /// Who drafted a language's text, when someone did: the assistant or
    /// the AI provider with open suggestions there.
    func drafter(of locale: StoreLocale) -> String? {
        suggestions.open(for: app.id, scope: .storePage(locale)).first { $0.source != .builtIn }?.source.title
    }

    // MARK: - The sheet

    /// "Languages in the app, not on the App Store": every project language
    /// the App Store page doesn't have, added or not, said Not Now to or
    /// not, in the project's order.
    var newLanguageRows: [NewLanguageRow] {
        let source = appSupport?.profile(for: app.id)?.languageSource
        return missingProjectLanguages.compactMap { language in
            guard let locale = language.storeLocale else { return nil }
            return NewLanguageRow(locale: locale, evidence: language.evidence(source: source), drafted: draftedLine(locale), isAdded: isAddedLanguage(locale))
        }
    }

    /// "Claude Code drafted 6 fields; they wait in its tab for you."
    private func draftedLine(_ locale: StoreLocale) -> String {
        let drafted = suggestions.open(for: app.id, scope: .storePage(locale)).filter { $0.source != .builtIn }
        guard let name = drafted.first?.source.title else {
            return String(localized: "Not drafted yet: connect an assistant or an AI provider, or write it yourself.")
        }
        let fields = Set(drafted.map(\.target.field)).count
        return fields == 1
            ? String(localized: "\(name) drafted 1 field; it waits in its tab for you.")
            : String(localized: "\(name) drafted \(fields) fields; they wait in its tab for you.")
    }

    /// "Found in Lumen Journal 1.4: Localizable.xcstrings in the Xcode
    /// project. Adding one creates its App Store page when you push."
    var newLanguagesSheetSubtitle: String {
        let subject = [app.name, content?.version.versionString].compactMap(\.self).joined(separator: " ")
        let source = appSupport?.profile(for: app.id)?.languageSource ?? String(localized: "the string catalogs")
        return String(localized: "Found in \(subject): \(source) in the Xcode project. Adding one creates its App Store page when you push.")
    }

    /// The checked languages that aren't added yet.
    var selectedNewLanguages: [StoreLocale] {
        newLanguageRows.filter { !$0.isAdded && languageSelection.contains($0.locale) }.map(\.locale)
    }

    /// "Add 3 Languages", "Add 1 Language", or "Add Languages" with none.
    var addSelectedLanguagesTitle: String {
        switch selectedNewLanguages.count {
        case 0: String(localized: "Add Languages")
        case 1: String(localized: "Add 1 Language")
        case let count: String(localized: "Add \(count) Languages")
        }
    }

    /// Review…: the sheet, with every suggested language checked.
    func presentNewLanguages() {
        languageSelection = Set(pendingLocales)
        sheet = .newLanguages
    }

    func toggleNewLanguage(_ locale: StoreLocale) {
        if languageSelection.contains(locale) { languageSelection.remove(locale) } else { languageSelection.insert(locale) }
    }

    func addSelectedLanguages() {
        let selected = selectedNewLanguages
        sheet = nil
        addLanguages(selected)
    }

    // MARK: - Deciding

    /// "Add All 3" on the banner.
    func addAllPendingLanguages() {
        addLanguages(pendingLocales)
    }

    /// "Create Page" on a suggested language's tab.
    func createPage(_ locale: StoreLocale) {
        addLanguages([locale], toast: String(localized: """
        Added \(locale.name). The page is created in App Store Connect when you push; accept or edit the drafted text below.
        """))
    }

    /// Adds project languages as new App Store pages: each one's page is
    /// created when you push, with whatever text it has by then. Undo, on
    /// the toast or in Edit, takes them back out.
    func addLanguages(_ locales: [StoreLocale], toast text: String? = nil) {
        guard var edited = listing else { return }
        let added = locales.filter { !edited.contains($0) }
        guard !added.isEmpty else { return }
        for locale in added {
            edited.addLocale(locale)
            appSupport?.undecline(locale.code, for: app.id)
        }
        keepAdded(added)
        commit(edited)
        let names = added.map(\.name).joined(separator: ", ")
        let message = text ?? (added.count == 1
            ? String(localized: "Added \(names). The page is created in App Store Connect when you push; its drafted text is in its tab.")
            : String(localized: "Added \(names). The pages are created in App Store Connect when you push; their drafted text is in each tab."))
        suggestionUndo = nil
        addedLanguagesUndo = added
        toast = ToastMessage(text: message, canUndo: true)
        registerLanguageUndo(added, name: added.count == 1 ? String(localized: "Add Language") : String(localized: "Add Languages"))
    }

    /// "Not Now" on a suggested language's tab: it stops being suggested
    /// (on this Mac, for this app) and the editor goes to the primary
    /// language.
    func declineLanguage(_ locale: StoreLocale) {
        appSupport?.decline(locale.code, for: app.id)
        refreshSuggestions()
        if editorLocale == locale { editorLocale = listing?.primaryLocale }
    }

    /// "Don’t Add" on an added language's tab: its page won't be created,
    /// its text goes, and the suggestions it took are open again.
    func removeLanguage(_ locale: StoreLocale) {
        guard var edited = listing, edited.contains(locale), !storeLocales.contains(locale) else { return }
        for field in ListingField.allCases {
            _ = suggestions.undoAcceptance(of: .storePage(locale, field), appID: app.id)
        }
        edited.removeLocale(locale)
        forgetAdded(locale)
        commit(edited, replacing: ListingField.allCases.map { ListingFieldKey(locale, $0) })
    }

    /// The toast's Undo after adding languages.
    func undoAddingLanguages() {
        guard let locales = addedLanguagesUndo else { return }
        undoManager?.removeAllActions(withTarget: self)
        takeBackLanguages(locales)
    }

    /// The toast's Undo: languages just added, or the last batch of
    /// suggestions.
    func undoToast() {
        if addedLanguagesUndo != nil { undoAddingLanguages() } else { undoLastSuggestionBatch() }
    }

    private func takeBackLanguages(_ locales: [StoreLocale]) {
        for locale in locales {
            removeLanguage(locale)
        }
        if addedLanguagesUndo == locales { addedLanguagesUndo = nil }
        toast = nil
    }

    private func registerLanguageUndo(_ locales: [StoreLocale], name: String) {
        guard let undoManager else { return }
        undoManager.registerUndo(withTarget: self) { model in
            MainActor.assumeIsolated { model.takeBackLanguages(locales) }
        }
        undoManager.setActionName(name)
    }
}
