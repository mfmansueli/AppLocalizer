//
//  ScreenshotsContext+Vision.swift
//  AppLocalizer
//

import Foundation

/// Apple Vision Pro screenshots belong to the app's visionOS version, whose
/// localizations App Store Connect keeps apart from the iOS version's.
extension ScreenshotsContext {
    /// The localization a device's screenshots go in.
    func localizationID(for locale: StoreLocale, displayType: ScreenshotDisplayType) -> String? {
        displayType == .visionPro ? visionLocalizations[locale] : localizations[locale]
    }

    /// The visionOS version that goes with `content`'s: the one with the
    /// same version string, else the newest editable one, else the newest.
    static func visionVersionID(in content: StorePageContent) -> String? {
        let vision = content.versions
            .filter { $0.platform == "VISION_OS" }
            .sorted { ($0.createdDate ?? .distantPast) > ($1.createdDate ?? .distantPast) }
        let match = vision.first { $0.versionString == content.version.versionString }
        return (match ?? StorePageVersion.preferred(in: vision))?.id
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
}
