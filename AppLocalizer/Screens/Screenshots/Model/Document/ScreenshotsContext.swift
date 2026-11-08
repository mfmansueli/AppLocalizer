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
    /// The app has a visionOS version on App Store Connect: Apple Vision Pro
    /// needs screenshots.
    var hasVisionVersion = false
    /// The visionOS version's `appStoreVersionLocalizations` IDs, where
    /// Apple Vision Pro screenshots go; empty until they're read.
    var visionLocalizations: [StoreLocale: String] = [:]
    /// The version's build has an Apple Watch app: Apple Watch needs
    /// screenshots. False until it's read.
    var hasWatchApp = false
    /// The app has a macOS version on App Store Connect (a Mac app, or an
    /// iPad app made for Mac): Mac needs screenshots.
    var hasMacVersion = false
    /// The version open is that macOS version itself.
    var isMacVersion = false
    /// The macOS version's `appStoreVersionLocalizations` IDs, where Mac
    /// screenshots go; empty until they're read.
    var macLocalizations: [StoreLocale: String] = [:]

    init(content: StorePageContent) {
        let version = content.version
        primaryLocale = content.primaryLocale
        self.version = ScreenshotsVersion(
            id: version.id, versionString: version.versionString, stateTitle: version.state.title, isEditable: version.isEditable
        )
        localizations = content.ids.versionLocalizations
        hasVisionVersion = content.versions.contains { $0.platform == Self.visionPlatform }
        hasMacVersion = content.versions.contains { $0.platform == Self.macPlatform }
        isMacVersion = version.platform == Self.macPlatform
    }

    init(primaryLocale: StoreLocale, version: ScreenshotsVersion, localizations: [StoreLocale: String] = [:]) {
        self.primaryLocale = primaryLocale
        self.version = version
        self.localizations = localizations
    }
}
