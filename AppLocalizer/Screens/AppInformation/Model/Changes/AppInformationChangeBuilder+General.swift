//
//  AppInformationChangeBuilder+General.swift
//  AppLocalizer
//

import Foundation

// General: categories (relationships of the app info), content rights (an
// attribute of the app), copyright and release (attributes of the version).
extension AppInformationChangeBuilder {
    enum GeneralKey {
        static let primaryCategory = "primaryCategory"
        static let secondaryCategory = "secondaryCategory"
        static let gamesSubcategories = "gamesSubcategories"
        static let contentRights = "contentRights"
        static let copyright = "copyright"
        static let release = "release"
    }

    static let subcategoryRelationships = ["primarySubcategoryOne", "primarySubcategoryTwo"]

    // MARK: - Building

    /// The primary or secondary category; nil when it's back at App Store
    /// Connect's value.
    func categoryChange(_ relationship: String, from old: String?, to new: String?, source: ChangeSource = .you) -> PendingChange? {
        guard old != new else { return nil }
        let path = "/v1/appInfos/\(ids.appInfoID)"
        let isPrimary = relationship == GeneralKey.primaryCategory
        return PendingChange(
            id: changeID(.general, relationship),
            appID: appID,
            section: .appInformation,
            group: group(.general),
            title: isPrimary ? String(localized: "Primary category") : String(localized: "Secondary category"),
            oldValue: AppCategory.name(for: old),
            newValue: AppCategory.name(for: new),
            source: source,
            blockedReason: isPrimary && new == nil ? String(localized: "Choose a primary category.") : nil,
            requests: [Self.patch("appInfos", id: ids.appInfoID, relationships: [relationship: Self.category(new)])],
            restoreRequests: [Self.patch("appInfos", id: ids.appInfoID, relationships: [relationship: Self.category(old)])],
            conflictCheck: ConflictCheck(path: "\(path)/relationships/\(relationship)", keyPath: ["data", "id"], expected: old)
        )
    }

    /// Up to two Games subcategories, sent together.
    func gamesSubcategoriesChange(from old: [String], to new: [String], source: ChangeSource = .you) -> PendingChange? {
        guard old != new else { return nil }
        let names = { (ids: [String]) in ids.isEmpty ? String(localized: "None") : ids.map { AppCategory.name(for: $0) }.joined(separator: ", ") }
        return PendingChange(
            id: changeID(.general, GeneralKey.gamesSubcategories),
            appID: appID,
            section: .appInformation,
            group: group(.general),
            title: String(localized: "Games subcategories"),
            oldValue: names(old),
            newValue: names(new),
            source: source,
            requests: [Self.patch("appInfos", id: ids.appInfoID, relationships: Self.subcategories(new))],
            restoreRequests: [Self.patch("appInfos", id: ids.appInfoID, relationships: Self.subcategories(old))],
            conflictCheck: ConflictCheck(
                path: "/v1/appInfos/\(ids.appInfoID)/relationships/\(Self.subcategoryRelationships[0])",
                keyPath: ["data", "id"],
                expected: old.first
            )
        )
    }

    /// Third-party content. A Yes waits for "I have the rights to use it".
    func contentRightsChange(from old: ContentRights?, to new: ContentRights?, rightsConfirmed: Bool, source: ChangeSource = .you) -> PendingChange? {
        guard old != new, let new else { return nil }
        let path = "/v1/apps/\(appID)"
        let needsRights = new == .usesThirdPartyContent && !rightsConfirmed
        return PendingChange(
            id: changeID(.general, GeneralKey.contentRights),
            appID: appID,
            section: .appInformation,
            group: group(.general),
            title: String(localized: "Third-party content"),
            oldValue: Self.display(old?.title),
            newValue: new.title,
            source: source,
            blockedReason: needsRights ? String(localized: "Confirm you have the rights to use the third-party content first.") : nil,
            requests: [Self.patch("apps", id: appID, attributes: ["contentRightsDeclaration": .string(new.rawValue)])],
            restoreRequests: old.map { [Self.patch("apps", id: appID, attributes: ["contentRightsDeclaration": .string($0.rawValue)])] } ?? [],
            conflictCheck: Self.attributeCheck("\(path)?fields[apps]=contentRightsDeclaration", key: "contentRightsDeclaration", expected: old?.rawValue)
        )
    }

    func copyrightChange(from old: String, to new: String, source: ChangeSource = .you) -> PendingChange? {
        guard old != new, let versionID = ids.versionID else { return nil }
        return PendingChange(
            id: versionChangeID(.general, GeneralKey.copyright),
            appID: appID,
            section: .appInformation,
            group: group(.general),
            title: versionTitle(String(localized: "Copyright")),
            oldValue: Self.display(old),
            newValue: Self.display(new),
            source: source,
            requests: [Self.patch("appStoreVersions", id: versionID, attributes: ["copyright": .text(new)])],
            restoreRequests: [Self.patch("appStoreVersions", id: versionID, attributes: ["copyright": .text(old)])],
            conflictCheck: Self.attributeCheck(
                "/v1/appStoreVersions/\(versionID)?fields[appStoreVersions]=copyright",
                key: "copyright",
                expected: old.isEmpty ? nil : old
            )
        )
    }

    /// Manually, after approval, or on a date (the earliest release date,
    /// on the hour).
    func releaseChange(from old: (ReleaseOption?, Date?), to new: (ReleaseOption, Date?), source: ChangeSource = .you) -> PendingChange? {
        let newDate = new.0 == .scheduled ? new.1.map(Self.onTheHour) : nil
        let oldDate = old.0 == .scheduled ? old.1 : nil
        guard old.0 != new.0 || oldDate != newDate, let versionID = ids.versionID else { return nil }
        return PendingChange(
            id: versionChangeID(.general, GeneralKey.release),
            appID: appID,
            section: .appInformation,
            group: group(.general),
            title: versionTitle(String(localized: "Release")),
            oldValue: Self.display(old.0.map { Self.releaseText($0, date: oldDate) }),
            newValue: Self.releaseText(new.0, date: newDate),
            source: source,
            blockedReason: new.0 == .scheduled && newDate == nil ? String(localized: "Choose the release date.") : nil,
            requests: [Self.patch("appStoreVersions", id: versionID, attributes: Self.releaseAttributes(new.0, date: newDate))],
            restoreRequests: old.0.map { [Self.patch("appStoreVersions", id: versionID, attributes: Self.releaseAttributes($0, date: oldDate))] } ?? [],
            conflictCheck: Self.attributeCheck(
                "/v1/appStoreVersions/\(versionID)?fields[appStoreVersions]=releaseType",
                key: "releaseType",
                expected: old.0?.rawValue
            )
        )
    }

    // MARK: - Reading

    /// App Store Connect's values with the queued General changes on top.
    func general(_ values: GeneralValues, with changes: [PendingChange]) -> GeneralValues {
        var values = values
        for change in changes where owns(change) {
            guard let document = Self.document(of: change) else { continue }
            switch change.id {
            case changeID(.general, GeneralKey.primaryCategory):
                values.primaryCategory = document.relationshipID(GeneralKey.primaryCategory)
            case changeID(.general, GeneralKey.secondaryCategory):
                values.secondaryCategory = document.relationshipID(GeneralKey.secondaryCategory)
            case changeID(.general, GeneralKey.gamesSubcategories):
                values.gamesSubcategories = Self.subcategoryRelationships.compactMap(document.relationshipID)
            case changeID(.general, GeneralKey.contentRights):
                values.contentRights = document.attribute("contentRightsDeclaration")?.stringValue.flatMap(ContentRights.init(rawValue:))
                values.rightsConfirmed = change.blockedReason == nil
            case versionChangeID(.general, GeneralKey.copyright):
                values.copyright = document.attribute("copyright")?.stringValue ?? ""
            case versionChangeID(.general, GeneralKey.release):
                values.release = document.attribute("releaseType")?.stringValue.flatMap(ReleaseOption.init(rawValue:))
                values.earliestReleaseDate = document.attribute("earliestReleaseDate")?.stringValue.flatMap(Self.date) ?? values.earliestReleaseDate
            default:
                continue
            }
        }
        return values
    }

    // MARK: - Helpers

    static func category(_ id: String?) -> AppInformationWriteDocument.Relationship {
        AppInformationWriteDocument.Relationship(data: id.map { AppInformationWriteDocument.Identifier(type: "appCategories", id: $0) })
    }

    static func subcategories(_ ids: [String]) -> [String: AppInformationWriteDocument.Relationship] {
        Dictionary(uniqueKeysWithValues: subcategoryRelationships.enumerated().map { index, name in
            (name, category(ids.indices.contains(index) ? ids[index] : nil))
        })
    }

    static func releaseAttributes(_ option: ReleaseOption, date: Date?) -> [String: AppInformationAPIValue] {
        var attributes: [String: AppInformationAPIValue] = ["releaseType": .string(option.rawValue)]
        if option == .scheduled, let date { attributes["earliestReleaseDate"] = .string(date.formatted(.iso8601)) }
        return attributes
    }

    static func releaseText(_ option: ReleaseOption, date: Date?) -> String {
        guard option == .scheduled, let date else { return option.title }
        return String(localized: "On \(date.formatted(date: .abbreviated, time: .shortened))")
    }

    static func date(_ text: String) -> Date? {
        try? Date(text, strategy: .iso8601)
    }

    /// App Store Connect takes release dates on the hour.
    static func onTheHour(_ date: Date) -> Date {
        Calendar.current.dateInterval(of: .hour, for: date)?.start ?? date
    }
}
