//
//  MCPListingDraft.swift
//  AppLocalizer
//

import Foundation

/// One app's store listing as an assistant sees it: App Store Connect's texts
/// for the newest editable version (else the live one) with everything
/// already queued laid on top, exactly as the Store Page shows it.
/// Proposals change the draft; `commit(to:)` queues them the way the Store
/// Page does, so an open Store Page picks them up from the queue.
///
/// Languages the app's project has and its App Store page doesn't
/// (`newLanguages`) can be suggested too: they show in their own tab of the
/// Store Page, and their page is created only once the person adds it.
@MainActor
struct MCPListingDraft {
    let app: StoreApp
    let content: StorePageContent
    let builder: ListingChangeBuilder
    private(set) var listing: StoreListing
    /// The project's languages that aren't on the App Store, not added here
    /// and not said Not Now to, in the project's order. Empty while the
    /// version can't change.
    var newLanguages: [ProjectLanguage] = []
    /// The project's languages the person said Not Now to.
    var declinedLanguages: [StoreLocale] = []
    /// Every language the project has and the App Store page doesn't.
    var missingLanguages: [ProjectLanguage] = []
    /// The project's catalog the languages come from, e.g.
    /// "Localizable.xcstrings".
    var languageSource: String?
    /// Fields a proposal changed since loading.
    private var touched: [ListingFieldKey] = []

    static func load(app identifier: String, in workspace: MCPWorkspace) async throws -> MCPListingDraft {
        let app = try await workspace.app(matching: identifier)
        let services = workspace.services.storePage
        let content: StorePageContent
        do {
            content = try await services.content(for: app, versionID: nil)
        } catch {
            throw MCPToolError.unavailable(String(localized: "Couldn’t read \(app.name)’s store listing: \(error.localizedDescription)"))
        }
        let support = services.appSupport
        let storeCodes = content.locales.map(\.code)
        let missing = support?.missingLanguages(for: app.id, storeLocales: storeCodes) ?? []
        var builder = ListingChangeBuilder(appID: app.id, ids: content.ids, versionString: content.version.versionString)
        builder.newPages = Set(missing.compactMap(\.storeLocale))
        let tags = MachineTranslationScope.tags(in: services.machineTranslations, appID: app.id, ids: content.ids)
        var listing = content.listing(machineTranslated: tags)
        builder.apply(workspace.changes.changes(for: app.id, section: .storePage), to: &listing, machineTranslated: tags)
        // A queued new locale App Store Connect has by now becomes edits of
        // what's there; the texts laid on the listing stay the same.
        builder.replaceStaleCreations(in: workspace.changes, listing: listing)
        var draft = MCPListingDraft(app: app, content: content, builder: builder, listing: listing)
        draft.missingLanguages = missing
        if let support, listing.version.isEditable {
            draft.newLanguages = support.pendingLanguages(for: app.id, storeLocales: storeCodes).filter { language in
                language.storeLocale.map { !listing.contains($0) } ?? false
            }
            draft.declinedLanguages = missing.compactMap(\.storeLocale).filter { locale in
                support.isDeclined(locale.code, for: app.id) && !listing.contains(locale)
            }
        }
        draft.languageSource = support?.profile(for: app.id)?.languageSource
        return draft
    }

    // MARK: - Reading

    /// The version these texts belong to, for tool results.
    var versionJSON: JSONValue {
        let version = listing.version
        return [
            "versionString": .string(version.versionString),
            "state": .string(version.state.title),
            "editable": .bool(version.isEditable),
        ]
    }

    /// The locales an assistant asked for, by code; every locale when nil,
    /// with the new languages after them when `includingNew`. Unknown codes
    /// and locales the app doesn't have are refused; a new language is
    /// taken when named.
    func locales(_ codes: [String]?, includingNew: Bool = false) throws -> [StoreLocale] {
        guard let codes else { return listing.displayLocales + (includingNew ? newLanguageLocales : []) }
        return try codes.map { code in
            guard let locale = StoreLocaleCatalog.locale(code: code), listing.contains(locale) || isNewLanguage(locale) else {
                throw MCPToolError.notFound(unknownLocaleMessage(code))
            }
            return locale
        }
    }

    /// "Lumen Journal has no locale “xx”. Its locales are en-US, de-DE; the
    /// app also supports pl, tr, which aren’t on the App Store yet."
    func unknownLocaleMessage(_ code: String) -> String {
        if let locale = StoreLocaleCatalog.locale(code: code), declinedLanguages.contains(locale) {
            return String(localized: "The person said Not Now to a \(locale.name) page for \(app.name). Leave \(code) out unless they add it.")
        }
        let known = listing.displayLocales.map(\.code).joined(separator: ", ")
        guard !newLanguages.isEmpty else { return String(localized: "\(app.name) has no locale “\(code)”. Its locales are \(known).") }
        let new = newLanguageLocales.map(\.code).joined(separator: ", ")
        return String(localized: "\(app.name) has no locale “\(code)”. Its locales are \(known); the app also supports \(new), which aren’t on the App Store yet.")
    }

    // MARK: - New languages

    var newLanguageLocales: [StoreLocale] { newLanguages.compactMap(\.storeLocale) }

    /// The app's project has it and the App Store page doesn't: suggestions
    /// for it show in its own tab until the person adds it.
    func isNewLanguage(_ locale: StoreLocale) -> Bool {
        newLanguageLocales.contains(locale)
    }

    /// Added here and not pushed yet: its page is created when the person
    /// pushes.
    func isUnpushed(_ locale: StoreLocale) -> Bool {
        listing.contains(locale) && !content.locales.contains(locale)
    }

    /// `languagesNotOnAppStore`: each language the project has and the App
    /// Store page doesn't, with how much of it is translated, and whether
    /// it's added (created on push) or was said Not Now to.
    var languagesNotOnAppStoreJSON: JSONValue {
        func entry(_ locale: StoreLocale, _ status: String) -> JSONValue {
            var json: [String: JSONValue] = ["code": .string(locale.code), "name": .string(locale.name), "status": .string(status)]
            if let language = projectLanguage(for: locale) {
                if let coverage = language.coverage { json["translated"] = .string(coverage) }
                if let note = language.note { json["note"] = .string(note) }
            }
            if let languageSource { json["source"] = .string(languageSource) }
            return .object(json)
        }
        let added = listing.displayLocales.filter { isUnpushed($0) && builder.newPages.contains($0) }
        return .array(
            newLanguageLocales.map { entry($0, "suggested") }
                + added.map { entry($0, "added") }
                + declinedLanguages.map { entry($0, "notNow") }
        )
    }

    private func projectLanguage(for locale: StoreLocale) -> ProjectLanguage? {
        missingLanguages.first { $0.storeLocale == locale }
    }

    /// "Lumen Journal · version 1.4".
    var target: String {
        String(localized: "\(app.name) · version \(listing.version.versionString)")
    }

    /// "Lumen Journal · de-DE · Subtitle".
    func target(locale code: String, field: ListingField?) -> String {
        [app.name, code, field?.title].compactMap(\.self).joined(separator: " · ")
    }

    // MARK: - Proposing

    /// An assistant's text for one field, validated like an edit in the
    /// Store Page.
    mutating func propose(_ text: String, for field: ListingField, locale code: String, by client: String) -> ListingProposalOutcome {
        let outcome = listing.propose(text, for: field, localeCode: code, by: client)
        switch outcome {
        case .queued, .conflict:
            if let locale = StoreLocaleCatalog.locale(code: code) { touched.append(ListingFieldKey(locale, field)) }
        case .unchanged, .refused:
            break
        }
        return outcome
    }

    /// A suggestion the person accepted, the way the Store Page accepts one:
    /// tagged with who suggested it, and replacing whatever was queued.
    mutating func accept(_ value: String, for field: ListingField, in locale: StoreLocale, from source: ChangeSource) {
        listing.update(field, in: locale) { $0.acceptSuggestion(value, from: source) }
        touched.append(ListingFieldKey(locale, field))
    }

    /// The ids a field's value can be queued under: its own change, or its
    /// language's new localization.
    func changeIDs(for key: ListingFieldKey) -> [PendingChange.ID] {
        [builder.changeID(for: key), builder.newLocaleChangeID(for: key.locale, at: key.field.level)]
    }

    /// Queues the proposed fields and returns each one's change ID. A field
    /// proposed back to App Store Connect's value leaves the queue.
    func commit(to queue: ChangeQueue) -> [ListingFieldKey: PendingChange.ID] {
        let desired = builder.changes(for: listing)
        var ids: [ListingFieldKey: PendingChange.ID] = [:]
        var upserts: [PendingChange] = []
        for key in touched where ids[key] == nil {
            let candidates = changeIDs(for: key)
            if let change = desired.first(where: { candidates.contains($0.id) }) {
                ids[key] = change.id
                if !upserts.contains(where: { $0.id == change.id }) { upserts.append(change) }
            } else {
                queue.discard(id: builder.changeID(for: key))
            }
        }
        queue.upsert(contentsOf: upserts)
        return ids
    }
}
