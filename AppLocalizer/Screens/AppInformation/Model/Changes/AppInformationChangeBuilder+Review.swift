//
//  AppInformationChangeBuilder+Review.swift
//  AppLocalizer
//

import Foundation

// App Review: one change per field of the version's review details, or a
// single `POST` creating them when the version has none yet. The password
// never goes into a change: the request carries a `{secret:…}` placeholder
// that Review & Push fills from the Keychain when it sends it.
extension AppInformationChangeBuilder {
    static let newReviewDetailKey = "new"
    static let masked = "••••••••"

    /// The Keychain item that holds this version's demo password.
    var passwordSecretName: String {
        "appInformation.\(appID).appReview.\(ids.versionID ?? "none").password"
    }

    func reviewChangeID(_ field: AppReviewField) -> String {
        versionChangeID(.appReview, field.rawValue)
    }

    var newReviewDetailChangeID: String { versionChangeID(.appReview, Self.newReviewDetailKey) }

    /// One field of existing review details; nil when it's back at App
    /// Store Connect's value.
    func reviewFieldChange(_ field: AppReviewField, from old: AppReviewValues, to new: AppReviewValues, source: ChangeSource = .you) -> PendingChange? {
        guard let detailID = ids.reviewDetailID, Self.value(field, in: old) != Self.value(field, in: new) else { return nil }
        let path = "/v1/appStoreReviewDetails/\(detailID)"
        let isPassword = field == .password
        let request = Self.patch("appStoreReviewDetails", id: detailID, attributes: [field.apiKey: apiValue(field, in: new)])
        return PendingChange(
            id: reviewChangeID(field),
            appID: appID,
            section: .appInformation,
            group: group(.appReview),
            title: versionTitle(field.title),
            oldValue: Self.display(field, in: old),
            newValue: Self.display(field, in: new),
            source: source,
            blockedReason: Self.reviewProblem(field, in: new),
            requests: [request],
            restoreRequests: isPassword ? [] : [Self.patch("appStoreReviewDetails", id: detailID, attributes: [field.apiKey: apiValue(field, in: old)])],
            conflictCheck: isPassword || field == .signInRequired
                ? nil
                : Self.attributeCheck("\(path)?fields[appStoreReviewDetails]=\(field.apiKey)", key: field.apiKey, expected: Self.value(field, in: old))
        )
    }

    /// Review details for a version that has none: everything in one `POST`.
    func newReviewDetailChange(_ values: AppReviewValues, source: ChangeSource = .you) -> PendingChange? {
        guard ids.reviewDetailID == nil, let versionID = ids.versionID, values != AppReviewValues() else { return nil }
        var attributes: [String: AppInformationAPIValue] = [:]
        for field in AppReviewField.allCases where field == .signInRequired || !values.text(field).isEmpty {
            attributes[field.apiKey] = apiValue(field, in: values)
        }
        let document = AppInformationWriteDocument.create(
            type: "appStoreReviewDetails",
            attributes: attributes,
            parent: "appStoreVersion",
            parentType: "appStoreVersions",
            parentID: versionID
        )
        let contact = [values.firstName, values.lastName].filter { !$0.isEmpty }.joined(separator: " ")
        return PendingChange(
            id: newReviewDetailChangeID,
            appID: appID,
            section: .appInformation,
            group: group(.appReview),
            title: versionTitle(String(localized: "App Review details")),
            oldValue: String(localized: "None"),
            newValue: [contact, values.email].filter { !$0.isEmpty }.joined(separator: " · "),
            source: source,
            blockedReason: Self.newReviewDetailProblem(values)
                ?? AppReviewField.allCases.lazy.compactMap { Self.reviewProblem($0, in: values) }.first,
            requests: [PushRequest(method: .post, path: "/v1/appStoreReviewDetails", body: document.encoded())]
        )
    }

    /// App Store Connect won't create review details without a contact
    /// email ("ENTITY_ERROR.ATTRIBUTE.REQUIRED — You must provide a value
    /// for the attribute 'contactEmail'").
    static func newReviewDetailProblem(_ values: AppReviewValues) -> String? {
        guard values.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return String(localized: "Add a contact email: App Store Connect needs one to create the review details.")
    }

    // MARK: - Reading

    /// App Store Connect's review details with the queued fields on top.
    /// A queued password is read from `password` (the Keychain).
    func review(_ values: AppReviewValues, with changes: [PendingChange], password: () -> String?) -> AppReviewValues {
        var values = values
        for change in changes where owns(change) && page(of: change) == .appReview {
            guard let attributes = Self.document(of: change)?.data.attributes else { continue }
            for (key, value) in attributes {
                guard let field = AppReviewField.field(apiKey: key) else { continue }
                switch field {
                case .signInRequired: values.signInRequired = value.boolValue ?? false
                case .password: values.password = password() ?? ""
                default: values.setText(value.stringValue ?? "", for: field)
                }
            }
        }
        return values
    }

    // MARK: - Helpers

    private func apiValue(_ field: AppReviewField, in values: AppReviewValues) -> AppInformationAPIValue {
        switch field {
        case .signInRequired: .bool(values.signInRequired)
        case .password: values.password.isEmpty ? .null : .string(PushRequest.secretPlaceholder(named: passwordSecretName))
        default: .text(values.text(field))
        }
    }

    /// The field's value as compared and conflict-checked; nil when empty.
    private static func value(_ field: AppReviewField, in values: AppReviewValues) -> String? {
        if field == .signInRequired { return values.signInRequired ? "1" : "0" }
        let text = values.text(field)
        return text.isEmpty ? nil : text
    }

    private static func display(_ field: AppReviewField, in values: AppReviewValues) -> String {
        switch field {
        case .signInRequired: yesNo(values.signInRequired)
        case .password: values.password.isEmpty ? display(nil) : masked
        default: display(values.text(field))
        }
    }

    private static func yesNo(_ flag: Bool) -> String {
        flag ? String(localized: "Yes") : String(localized: "No")
    }

    /// Notes over 4,000 characters can't be pushed.
    private static func reviewProblem(_ field: AppReviewField, in values: AppReviewValues) -> String? {
        guard field == .notes, values.notes.count > AppReviewField.notesLimit else { return nil }
        return String(localized: "Notes are \(values.notes.count) characters; App Store Connect takes 4,000.")
    }
}
