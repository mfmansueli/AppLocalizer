//
//  ListingChangeBuilder.swift
//  AppLocalizer
//

import Foundation

/// Turns a listing's pending fields into Review & Push changes, with the
/// exact App Store Connect writes, and reads queued changes back onto a
/// listing (`ListingChangeBuilder+Reading.swift`), so the queue is the one
/// place edits live: they survive navigation and relaunch, and discarding
/// one in review reverts the field.
///
/// - A field of a locale App Store Connect already has is one change:
///   `PATCH` its localization, restore by patching the old text back, and a
///   conflict check on the field's current value.
/// - A locale that doesn't exist at that level yet is one change for all of
///   its pending fields: a single `POST` creates the localization with
///   them, since a second `POST` for the same locale would be refused.
///   It can't be restored (the new localization's ID isn't known here).
/// - Ids are `storePage.<appID>.version.<versionID>.<locale>.<field>` or
///   `storePage.<appID>.appInfo.<appInfoID>.<locale>.<field>`, and
///   `….<locale>.new` for a new locale.
struct ListingChangeBuilder: Hashable, Sendable {
    let appID: StoreApp.ID
    let ids: ListingResourceIDs
    let versionString: String

    static let versionLocalizationType = "appStoreVersionLocalizations"
    static let appInfoLocalizationType = "appInfoLocalizations"
    static let newLocaleSuffix = "new"

    // MARK: - Ids and groups

    /// Every change id at `level` starts with this.
    func idPrefix(at level: ListingFieldLevel) -> String {
        switch level {
        case .app: "storePage.\(appID).appInfo.\(ids.appInfoID)."
        case .version: "storePage.\(appID).version.\(ids.versionID)."
        }
    }

    func changeID(for key: ListingFieldKey) -> String {
        idPrefix(at: key.field.level) + "\(key.locale.code).\(key.field.rawValue)"
    }

    func newLocaleChangeID(for locale: StoreLocale, at level: ListingFieldLevel) -> String {
        idPrefix(at: level) + "\(locale.code).\(Self.newLocaleSuffix)"
    }

    /// The level of a change this builder made, or nil when it's someone
    /// else's (another app, version or section).
    func level(of change: PendingChange) -> ListingFieldLevel? {
        guard change.section == .storePage, change.appID == appID else { return nil }
        if change.id.hasPrefix(idPrefix(at: .version)) { return .version }
        if change.id.hasPrefix(idPrefix(at: .app)) { return .app }
        return nil
    }

    func owns(_ change: PendingChange) -> Bool {
        level(of: change) != nil
    }

    /// The review sheet's heading: "Store Page · Version 1.4", or
    /// "Store Page · App information" for name, subtitle and privacy URL.
    func group(at level: ListingFieldLevel) -> String {
        switch level {
        case .app: String(localized: "Store Page · App information")
        case .version: String(localized: "Store Page · Version \(versionString)")
        }
    }

    static func localizationType(at level: ListingFieldLevel) -> String {
        level == .app ? appInfoLocalizationType : versionLocalizationType
    }

    // MARK: - Building

    /// One change per pending field, or per new locale and level: locales
    /// in display order, app-level fields before version-level ones.
    func changes(for listing: StoreListing) -> [PendingChange] {
        listing.displayLocales.flatMap { locale in
            [ListingFieldLevel.app, .version].flatMap { level in
                let pending = ListingField.allCases
                    .filter { $0.level == level }
                    .compactMap { listing.change(for: ListingFieldKey(locale, $0)) }
                guard !pending.isEmpty else { return [PendingChange]() }
                guard let localizationID = ids.localizationID(for: locale, at: level) else {
                    return [newLocaleChange(pending, locale: locale, level: level)]
                }
                return pending.map { fieldChange($0, localizationID: localizationID) }
            }
        }
    }

    private func fieldChange(_ change: ListingChange, localizationID: String) -> PendingChange {
        let field = change.field
        let type = Self.localizationType(at: field.level)
        let path = "/v1/\(type)/\(localizationID)"
        var pending = PendingChange(
            id: changeID(for: change.key),
            appID: appID,
            section: .storePage,
            group: group(at: field.level),
            title: change.title,
            flagRegion: change.locale.regionCode,
            oldValue: change.oldValue,
            newValue: change.newValue,
            source: change.source,
            blockedReason: blockedReason(change),
            requests: [Self.patch(path: path, type: type, id: localizationID, attributes: [field.rawValue: Self.apiValue(change.newValue)])],
            restoreRequests: [Self.patch(path: path, type: type, id: localizationID, attributes: [field.rawValue: Self.apiValue(change.oldValue)])],
            conflictCheck: ConflictCheck(path: path, keyPath: ["data", "attributes", field.rawValue], expected: Self.apiValue(change.oldValue))
        )
        if let proposal = change.conflictingProposal {
            pending.alternative = ChangeAlternative(
                newValue: proposal.value,
                source: .assistant(client: proposal.client),
                requests: [Self.patch(path: path, type: type, id: localizationID, attributes: [field.rawValue: Self.apiValue(proposal.value)])],
                restoreRequests: pending.restoreRequests
            )
        }
        return pending
    }

    private func newLocaleChange(_ changes: [ListingChange], locale: StoreLocale, level: ListingFieldLevel) -> PendingChange {
        var attributes: [String: String?] = ["locale": locale.code]
        for change in changes {
            attributes[change.field.rawValue] = Self.apiValue(change.newValue)
        }
        let document = StorePageWriteDocument.create(
            type: Self.localizationType(at: level),
            attributes: attributes,
            parent: level == .app ? "appInfo" : "appStoreVersion",
            parentType: level == .app ? "appInfos" : "appStoreVersions",
            parentID: ids.parentID(at: level)
        )
        let sources = Set(changes.map(\.source))
        let blocked = changes.lazy.compactMap { change in blockedReason(change).map { "\(change.field.title): \($0)" } }.first
        return PendingChange(
            id: newLocaleChangeID(for: locale, at: level),
            appID: appID,
            section: .storePage,
            group: group(at: level),
            title: changes.count == 1 ? changes[0].title : "\(locale.name) · " + String(localized: "New locale · \(changes.count) fields"),
            flagRegion: locale.regionCode,
            oldValue: "",
            newValue: changes.count == 1 ? changes[0].newValue : changes.map { "\($0.field.title): \($0.newValue)" }.joined(separator: " · "),
            source: sources.count == 1 ? changes[0].source : .you,
            blockedReason: blocked,
            requests: [PushRequest(method: .post, path: "/v1/\(Self.localizationType(at: level))", body: document.encoded())]
        )
    }

    /// Over the limit or an invalid URL. A you-versus-assistant conflict
    /// isn't a block here: the queue keeps it as the change's alternative.
    private func blockedReason(_ change: ListingChange) -> String? {
        switch change.blockReason {
        case .overLimit, .invalidURL: change.blockReason?.message
        case .conflict, nil: nil
        }
    }

    // MARK: - Requests

    static func patch(path: String, type: String, id: String, attributes: [String: String?]) -> PushRequest {
        PushRequest(method: .patch, path: path, body: StorePageWriteDocument.update(type: type, id: id, attributes: attributes).encoded())
    }

    /// Empty text is sent as `null`, which clears the field.
    static func apiValue(_ text: String) -> String? {
        text.isEmpty ? nil : text
    }
}
