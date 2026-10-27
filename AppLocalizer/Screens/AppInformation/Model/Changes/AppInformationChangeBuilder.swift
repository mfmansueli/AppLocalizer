//
//  AppInformationChangeBuilder.swift
//  AppLocalizer
//

import Foundation

/// Turns App Information edits into Review & Push changes, with the exact
/// App Store Connect writes, restore writes and conflict checks, and reads
/// queued changes back onto the pages, so the queue is the one place edits
/// live: they survive navigation and relaunch, and discarding one in
/// review reverts the page.
///
/// One change per field (per question, per device family), with stable
/// ids: `appInformation.<appID>.<page>.<key>` for the app's values and
/// `appInformation.<appID>.<page>.<versionID>.<key>` for one version's.
/// The pages' builders are in `AppInformationChangeBuilder+<Page>.swift`.
struct AppInformationChangeBuilder: Hashable, Sendable {
    let appID: StoreApp.ID
    let ids: AppInformationResourceIDs
    /// The shown version's number, e.g. "1.4".
    var versionString: String?

    // MARK: - Ids and groups

    /// Every change id this builder makes starts with this.
    var idPrefix: String { "appInformation.\(appID)." }

    func changeID(_ page: AppInformationPage, _ key: String) -> String {
        idPrefix + "\(page.rawValue).\(key)"
    }

    /// An id for one version's value, e.g. its copyright.
    func versionChangeID(_ page: AppInformationPage, _ key: String) -> String {
        changeID(page, "\(ids.versionID ?? "none").\(key)")
    }

    func owns(_ change: PendingChange) -> Bool {
        change.section == .appInformation && change.appID == appID && change.id.hasPrefix(idPrefix)
    }

    /// The page a change belongs to, for the page column's dot.
    func page(of change: PendingChange) -> AppInformationPage? {
        guard owns(change) else { return nil }
        let rest = change.id.dropFirst(idPrefix.count)
        return rest.split(separator: ".").first.flatMap { AppInformationPage(rawValue: String($0)) }
    }

    /// The review sheet's heading: "App Information · Age Rating".
    func group(_ page: AppInformationPage) -> String {
        String(localized: "App Information · \(page.title)")
    }

    /// "Copyright · 1.4": a version's value says which version.
    func versionTitle(_ title: String) -> String {
        guard let versionString else { return title }
        return "\(title) · \(versionString)"
    }

    /// The change at `id`, if one is queued.
    static func change(_ id: String, in changes: [PendingChange]) -> PendingChange? {
        changes.first { $0.id == id }
    }

    // MARK: - Requests

    static func patch(_ type: String, id: String, attributes: [String: AppInformationAPIValue]) -> PushRequest {
        let document = AppInformationWriteDocument.update(type: type, id: id, attributes: attributes)
        return PushRequest(method: .patch, path: "/v1/\(type)/\(id)", body: document.encoded())
    }

    static func patch(_ type: String, id: String, relationships: [String: AppInformationWriteDocument.Relationship]) -> PushRequest {
        let document = AppInformationWriteDocument.update(type: type, id: id, relationships: relationships)
        return PushRequest(method: .patch, path: "/v1/\(type)/\(id)", body: document.encoded())
    }

    /// The document of a queued change's first request.
    static func document(of change: PendingChange) -> AppInformationWriteDocument? {
        AppInformationWriteDocument.decode(change.requests.first?.body)
    }

    /// A check that `GET path` still has `expected` at `data.attributes.<key>`.
    static func attributeCheck(_ path: String, key: String, expected: String?) -> ConflictCheck {
        ConflictCheck(path: path, keyPath: ["data", "attributes", key], expected: expected)
    }

    /// "Not set" for nothing, for old and new values.
    static func display(_ text: String?) -> String {
        guard let text, !text.isEmpty else { return String(localized: "Not set") }
        return text
    }
}
