//
//  ScreenshotsContext+PlatformVersions.swift
//  AppLocalizer
//

import Foundation

/// Apple Vision Pro screenshots belong to the app's visionOS version and
/// Mac screenshots to its macOS version, whose localizations App Store
/// Connect keeps apart from the iOS version's.
extension ScreenshotsContext {
    static let visionPlatform = "VISION_OS"
    static let macPlatform = "MAC_OS"

    /// The localization a device's screenshots go in. A Mac app's own
    /// version takes Mac's.
    func localizationID(for locale: StoreLocale, displayType: ScreenshotDisplayType) -> String? {
        switch displayType {
        case .visionPro: visionLocalizations[locale]
        case .mac: isMacVersion ? localizations[locale] : macLocalizations[locale]
        default: localizations[locale]
        }
    }

    /// The visionOS version that goes with `content`'s.
    static func visionVersionID(in content: StorePageContent) -> String? {
        versionID(platform: visionPlatform, in: content)
    }

    /// The macOS version that goes with `content`'s.
    static func macVersionID(in content: StorePageContent) -> String? {
        versionID(platform: macPlatform, in: content)
    }

    /// The `platform` version that goes with `content`'s: the one with the
    /// same version string, else the newest editable one, else the newest.
    static func versionID(platform: String, in content: StorePageContent) -> String? {
        let versions = content.versions
            .filter { $0.platform == platform }
            .sorted { ($0.createdDate ?? .distantPast) > ($1.createdDate ?? .distantPast) }
        let match = versions.first { $0.versionString == content.version.versionString }
        return (match ?? StorePageVersion.preferred(in: versions))?.id
    }

    /// Reads the visionOS and macOS versions' localizations with `load`,
    /// when the app has them.
    @MainActor
    mutating func readPlatformLocalizations(
        in content: StorePageContent,
        load: (String) async throws -> StorePageContent
    ) async {
        await readVisionLocalizations(in: content, load: load)
        await readMacLocalizations(in: content, load: load)
    }

    /// Reads the visionOS version's localizations with `load`, when the app
    /// has one. A failure leaves them empty: Apple Vision Pro screenshots
    /// then wait, and everything else still works.
    @MainActor
    mutating func readVisionLocalizations(
        in content: StorePageContent,
        load: (String) async throws -> StorePageContent
    ) async {
        guard let id = Self.visionVersionID(in: content), id != content.version.id else { return }
        visionLocalizations = await (try? load(id))?.ids.versionLocalizations ?? [:]
    }

    /// Reads the macOS version's localizations with `load`, when the app has
    /// one apart from the version open. A failure leaves them empty: Mac
    /// screenshots then wait, and everything else still works.
    @MainActor
    mutating func readMacLocalizations(
        in content: StorePageContent,
        load: (String) async throws -> StorePageContent
    ) async {
        guard !isMacVersion, let id = Self.macVersionID(in: content), id != content.version.id else { return }
        macLocalizations = await (try? load(id))?.ids.versionLocalizations ?? [:]
    }
}
