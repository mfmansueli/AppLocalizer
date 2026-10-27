//
//  AppInformationChangeBuilder+PrivacyURLs.swift
//  AppLocalizer
//

import Foundation

// App Privacy's User Privacy Choices URL: one change per locale, a `PATCH`
// of its `appInfoLocalizations` resource. The Privacy Policy URL is Store
// Page's field, so its changes come from `ListingChangeBuilder`.
extension AppInformationChangeBuilder {
    static let choicesURLAttribute = "privacyChoicesUrl"

    func privacyChoicesChangeID(_ locale: StoreLocale) -> String {
        changeID(.appPrivacy, "choices.\(locale.code)")
    }

    /// Sets one locale's User Privacy Choices URL. Nil when it's App Store
    /// Connect's value already.
    func privacyChoicesChange(for remote: PrivacyURLsLocale, to value: String, source: ChangeSource = .you) -> PendingChange? {
        let new = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let old = remote.choicesURL
        guard new != old else { return nil }
        let type = ListingChangeBuilder.appInfoLocalizationType
        let path = "/v1/\(type)/\(remote.localizationID)"
        let blocked = new.isEmpty || ListingFieldValidator.isValidURL(new) ? nil : ListingBlockReason.invalidURL.message
        return PendingChange(
            id: privacyChoicesChangeID(remote.locale),
            appID: appID,
            section: .appInformation,
            group: group(.appPrivacy),
            title: String(localized: "\(remote.locale.name) · User Privacy Choices URL"),
            flagRegion: remote.locale.regionCode,
            oldValue: Self.display(old),
            newValue: Self.display(new),
            source: source,
            blockedReason: blocked,
            requests: [Self.patch(type, id: remote.localizationID, attributes: [Self.choicesURLAttribute: .text(new)])],
            restoreRequests: [Self.patch(type, id: remote.localizationID, attributes: [Self.choicesURLAttribute: .text(old)])],
            conflictCheck: Self.attributeCheck(path, key: Self.choicesURLAttribute, expected: old.isEmpty ? nil : old)
        )
    }

    /// The queued User Privacy Choices URL for `locale`, if one is queued.
    func queuedPrivacyChoicesURL(_ locale: StoreLocale, in changes: [PendingChange]) -> String? {
        guard let change = Self.change(privacyChoicesChangeID(locale), in: changes) else { return nil }
        return Self.document(of: change)?.attribute(Self.choicesURLAttribute)?.stringValue ?? ""
    }
}
