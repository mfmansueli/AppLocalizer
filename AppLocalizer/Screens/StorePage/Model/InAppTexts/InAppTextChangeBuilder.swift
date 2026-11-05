//
//  InAppTextChangeBuilder.swift
//  AppLocalizer
//

import Foundation

/// The In-App Texts' version of `ListingChangeBuilder`: pending cells become
/// Review & Push changes and queued changes are read back onto the matrix.
///
/// - An existing localization's cell is one `PATCH` of `name` or
///   `description`, restorable, with a conflict check.
/// - A locale the group or product doesn't have yet is one `POST` with
///   both texts. App Store Connect needs a name to create it, so a lone
///   description is blocked until a name is typed.
/// - Since API 4.4.1 the texts belong to a version (`Write`): writes go to
///   `/v2/…Localizations` in the editable version. An owner without one
///   gets one `POST` per locale with every text, into
///   `{inAppDraft:<owner>}`, which the push finds or creates and turns
///   into an update when the draft has that locale (`InAppDraftWrite`).
///   Legacy owners keep the `/v1` writes.
/// - Ids are `storePage.<appID>.inApp.<owner>.<locale>.<name|description>`,
///   or `….<locale>.new`, where the owner is `group.<groupID>` or
///   `product.<resourceID>`.
struct InAppTextChangeBuilder: Hashable, Sendable {
    let appID: StoreApp.ID
    let content: InAppTextsContent

    var idPrefix: String { "storePage.\(appID).inApp." }

    var group: String { String(localized: "Store Page · In-App Texts") }

    func owns(_ change: PendingChange) -> Bool {
        change.section == .storePage && change.appID == appID && change.id.hasPrefix(idPrefix)
    }

    /// One change per pending cell, or per new localization (every
    /// changed locale, for an owner whose draft the push makes).
    func changes(for matrix: InAppTextMatrix) -> [PendingChange] {
        let pending = matrix.changes
        var result: [PendingChange] = []
        for owner in owners {
            for locale in matrix.displayLocales {
                let cells = pending.filter { $0.locale == locale && $0.column.productID == owner.productID }
                guard !cells.isEmpty, let ownerID = owner.resourceID else { continue }
                let write = write(for: owner)
                if write != .draft, let localizationID = content.localizationID(productID: owner.productID, locale: locale) {
                    result += cells.map { cellChange($0, owner: owner, write: write, localizationID: localizationID) }
                } else {
                    result.append(newLocalizationChange(cells, matrix: matrix, owner: owner, ownerID: ownerID, write: write, locale: locale))
                }
            }
        }
        return result
    }

    // MARK: - Versions

    /// Where an owner's texts are written.
    enum Write: Hashable, Sendable {
        /// Pre-4.4.1: `/v1` localizations under the owner.
        case legacy
        /// `/v2` localizations in this editable version.
        case version(String)
        /// `/v2` localizations in a draft the push finds or creates.
        case draft
    }

    func write(for owner: Owner) -> Write {
        if content.legacyOwners.contains(owner.key) { return .legacy }
        return content.editableVersions[owner.key].map(Write.version) ?? .draft
    }

    // MARK: - Owners

    /// What a localization belongs to: the subscription group or a product.
    struct Owner: Hashable, Sendable {
        /// Nil for the group.
        let productID: String?
        let resourceID: String?
        let kind: InAppTextProductKind?

        /// `subscriptionGroupLocalizations`, `subscriptionLocalizations` or
        /// `inAppPurchaseLocalizations`.
        var localizationType: String {
            switch kind {
            case nil: "subscriptionGroupLocalizations"
            case .subscription: "subscriptionLocalizations"
            case .inAppPurchase: "inAppPurchaseLocalizations"
            }
        }

        /// The new localization's parent relationship and its type.
        var parent: (relationship: String, type: String) {
            switch kind {
            case nil: ("subscriptionGroup", "subscriptionGroups")
            case .subscription: ("subscription", "subscriptions")
            case .inAppPurchase: ("inAppPurchaseV2", "inAppPurchases")
            }
        }

        var idComponent: String {
            productID == nil ? "group.\(resourceID ?? "")" : "product.\(resourceID ?? "")"
        }

        /// `InAppTextsContent.groupKey` or the product ID.
        var key: String { productID ?? InAppTextsContent.groupKey }

        /// The versions its texts live in (API 4.4.1).
        var versionType: String {
            switch kind {
            case nil: "subscriptionGroupVersions"
            case .subscription: "subscriptionVersions"
            case .inAppPurchase: "inAppPurchaseVersions"
            }
        }

        /// `/v1` for the legacy subscription and group writes; purchases
        /// were already written there.
        func base(_ write: Write) -> String {
            write == .legacy ? "/v1" : "/v2"
        }
    }

    /// The ids a cell's value can be queued under: its own change, or its
    /// owner's new localization in that locale.
    func changeIDs(for column: InAppTextColumn, in locale: StoreLocale) -> [PendingChange.ID] {
        guard let owner = owners.first(where: { $0.productID == column.productID }) else { return [] }
        let attribute = column.field.isDescription ? "description" : "name"
        let base = idPrefix + "\(owner.idComponent).\(locale.code)."
        return [base + attribute, base + ListingChangeBuilder.newLocaleSuffix]
    }

    /// The group first, then each product, in column order.
    var owners: [Owner] {
        [Owner(productID: nil, resourceID: content.groupID, kind: nil)] + content.products.map { product in
            Owner(productID: product.id, resourceID: content.productResourceIDs[product.id], kind: product.kind)
        }
    }

    // MARK: - Building

    private func cellChange(_ cell: InAppTextChange, owner: Owner, write: Write, localizationID: String) -> PendingChange {
        let attribute = cell.column.field.isDescription ? "description" : "name"
        let path = "\(owner.base(write))/\(owner.localizationType)/\(localizationID)"
        let patch = { (text: String) in
            ListingChangeBuilder.patch(
                path: path,
                type: owner.localizationType,
                id: localizationID,
                attributes: [attribute: ListingChangeBuilder.apiValue(text)]
            )
        }
        return PendingChange(
            id: idPrefix + "\(owner.idComponent).\(cell.locale.code).\(attribute)",
            appID: appID,
            section: .storePage,
            group: group,
            title: cell.title,
            flagRegion: cell.locale.regionCode,
            oldValue: cell.oldValue,
            newValue: cell.newValue,
            source: cell.source,
            blockedReason: cell.blockReason?.message,
            requests: [patch(cell.newValue)],
            restoreRequests: [patch(cell.oldValue)],
            conflictCheck: ConflictCheck(path: path, keyPath: ["data", "attributes", attribute], expected: ListingChangeBuilder.apiValue(cell.oldValue))
        )
    }

    private func newLocalizationChange(
        _ cells: [InAppTextChange],
        matrix: InAppTextMatrix,
        owner: Owner,
        ownerID: String,
        write: Write,
        locale: StoreLocale
    ) -> PendingChange {
        let nameColumn = matrix.columns.first { $0.productID == owner.productID && !$0.field.isDescription }
        let descriptionColumn = matrix.columns.first { $0.productID == owner.productID && $0.field.isDescription }
        let name = nameColumn.map { matrix.value($0, in: locale) } ?? ""
        var attributes: [String: String?] = ["locale": locale.code, "name": ListingChangeBuilder.apiValue(name)]
        if let descriptionColumn {
            attributes["description"] = ListingChangeBuilder.apiValue(matrix.value(descriptionColumn, in: locale))
        }
        let document = switch write {
        case .legacy:
            StorePageWriteDocument.create(
                type: owner.localizationType,
                attributes: attributes,
                parent: owner.parent.relationship,
                parentType: owner.parent.type,
                parentID: ownerID
            )
        case let .version(versionID):
            StorePageWriteDocument.create(
                type: owner.localizationType,
                attributes: attributes,
                parent: "version",
                parentType: owner.versionType,
                parentID: versionID
            )
        case .draft:
            StorePageWriteDocument.create(
                type: owner.localizationType,
                attributes: attributes,
                parent: "version",
                parentType: owner.versionType,
                parentID: PushRequest.inAppDraftPlaceholder(ownerType: owner.parent.type, ownerID: ownerID)
            )
        }
        let blocked = cells.lazy.compactMap(\.blockReason?.message).first
            ?? (name.isEmpty ? String(localized: "Add a display name first: App Store Connect needs one to create this locale.") : nil)
        return PendingChange(
            id: idPrefix + "\(owner.idComponent).\(locale.code).\(ListingChangeBuilder.newLocaleSuffix)",
            appID: appID,
            section: .storePage,
            group: group,
            title: cells.count == 1 ? cells[0].title : cells[0].title.components(separatedBy: " · ").dropLast().joined(separator: " · "),
            flagRegion: locale.regionCode,
            oldValue: cells.map(\.oldValue).filter { !$0.isEmpty }.joined(separator: " · "),
            newValue: cells.map(\.newValue).joined(separator: " · "),
            source: cells[0].source,
            blockedReason: blocked,
            requests: [PushRequest(method: .post, path: "\(owner.base(write))/\(owner.localizationType)", body: document.encoded())]
        )
    }
}
