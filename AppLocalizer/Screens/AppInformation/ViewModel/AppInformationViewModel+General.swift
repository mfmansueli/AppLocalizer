//
//  AppInformationViewModel+General.swift
//  AppLocalizer
//

import Foundation

// General: categories and content rights for the app, copyright and
// release for the shown version.
extension AppInformationViewModel {
    private typealias Key = AppInformationChangeBuilder.GeneralKey

    /// App Store Connect's values with the queued ones on top.
    var general: GeneralValues? {
        content.map { builder.general($0.general, with: changes) }
    }

    func setPrimaryCategory(_ id: String?) {
        guard let content, let general, general.primaryCategory != id else { return }
        apply(builder.categoryChange(Key.primaryCategory, from: content.general.primaryCategory, to: id), id: builder.changeID(.general, Key.primaryCategory))
        // Subcategories belong to Games: picking another category clears them.
        if id != AppCategory.gamesID, !general.gamesSubcategories.isEmpty { setGamesSubcategories([]) }
    }

    func setSecondaryCategory(_ id: String?) {
        guard let content, general?.secondaryCategory != id else { return }
        apply(
            builder.categoryChange(Key.secondaryCategory, from: content.general.secondaryCategory, to: id),
            id: builder.changeID(.general, Key.secondaryCategory)
        )
    }

    /// One of the two Games subcategory pickers; nil clears it.
    func setGamesSubcategory(_ id: String?, at index: Int) {
        guard let general else { return }
        var subcategories = general.gamesSubcategories
        if index < subcategories.count {
            if let id { subcategories[index] = id } else { subcategories.remove(at: index) }
        } else if let id {
            subcategories.append(id)
        }
        setGamesSubcategories(Array(NSOrderedSet(array: subcategories).compactMap { $0 as? String }.prefix(2)))
    }

    private func setGamesSubcategories(_ ids: [String]) {
        guard let content else { return }
        apply(
            builder.gamesSubcategoriesChange(from: content.general.gamesSubcategories, to: ids),
            id: builder.changeID(.general, Key.gamesSubcategories)
        )
    }

    /// Yes or No to third-party content. Yes waits for the rights checkbox.
    func setContentRights(_ rights: ContentRights) {
        guard let content, let general, general.contentRights != rights else { return }
        let confirmed = rights == .usesThirdPartyContent && (content.general.contentRights == rights || general.rightsConfirmed)
        apply(
            builder.contentRightsChange(from: content.general.contentRights, to: rights, rightsConfirmed: confirmed),
            id: builder.changeID(.general, Key.contentRights)
        )
    }

    /// "I have the rights to use it, or it’s otherwise permitted".
    func setRightsConfirmed(_ confirmed: Bool) {
        guard let content, let general, general.contentRights == .usesThirdPartyContent else { return }
        apply(
            builder.contentRightsChange(from: content.general.contentRights, to: .usesThirdPartyContent, rightsConfirmed: confirmed),
            id: builder.changeID(.general, Key.contentRights)
        )
    }

    func setCopyright(_ text: String) {
        guard let content, content.isVersionEditable, general?.copyright != text else { return }
        apply(builder.copyrightChange(from: content.general.copyright, to: text), id: builder.versionChangeID(.general, Key.copyright))
    }

    func setRelease(_ option: ReleaseOption) {
        guard let general, general.release != option else { return }
        let date = option == .scheduled ? general.earliestReleaseDate ?? Self.defaultReleaseDate : general.earliestReleaseDate
        queueRelease(option, date: date)
    }

    /// The earliest release date, for "On a date".
    func setReleaseDate(_ date: Date) {
        guard let general, general.release == .scheduled else { return }
        queueRelease(.scheduled, date: date)
    }

    private func queueRelease(_ option: ReleaseOption, date: Date?) {
        guard let content, content.isVersionEditable else { return }
        let old = (content.general.release, content.general.earliestReleaseDate)
        apply(builder.releaseChange(from: old, to: (option, date)), id: builder.versionChangeID(.general, Key.release))
    }

    /// A week from now, on the hour: where "On a date" starts.
    private static var defaultReleaseDate: Date {
        AppInformationChangeBuilder.onTheHour(Date.now.addingTimeInterval(7 * 24 * 3600))
    }
}
