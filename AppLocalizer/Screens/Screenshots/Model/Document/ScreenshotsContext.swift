//
//  ScreenshotsContext.swift
//  AppLocalizer
//

import Foundation

/// What the Store Page tells the Screenshots view: the primary locale, the
/// version screenshots go with and its localizations' IDs.
struct ScreenshotsContext: Hashable, Sendable {
    var primaryLocale: StoreLocale
    var version: ScreenshotsVersion
    /// Each locale's `appStoreVersionLocalizations` ID.
    var localizations: [StoreLocale: String]

    init(content: StorePageContent) {
        let version = content.version
        primaryLocale = content.primaryLocale
        self.version = ScreenshotsVersion(
            id: version.id, versionString: version.versionString, stateTitle: version.state.title, isEditable: version.isEditable
        )
        localizations = content.ids.versionLocalizations
    }

    init(primaryLocale: StoreLocale, version: ScreenshotsVersion, localizations: [StoreLocale: String] = [:]) {
        self.primaryLocale = primaryLocale
        self.version = version
        self.localizations = localizations
    }
}
