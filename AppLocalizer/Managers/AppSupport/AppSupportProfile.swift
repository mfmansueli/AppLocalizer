//
//  AppSupportProfile.swift
//  AppLocalizer
//

import Foundation

/// What an app's Xcode project supports, beyond what its App Store page
/// shows: the devices its targets run on and the languages its strings are
/// translated into. The assistant reads the project and reports it
/// (`report_app_support`); AppLocalizer can't open the project itself.
struct AppSupportProfile: Codable, Hashable, Sendable {
    /// "Lumen (iOS, visionOS)", "LumenWatch Watch App".
    var targets: [String] = []
    /// iPhone is implied; the others the targets add.
    var devices: [SupportedDevice] = []
    var languages: [ProjectLanguage] = []
    /// Where the languages come from, e.g. "Localizable.xcstrings".
    var languageSource: String?
    /// The assistant that read the project, e.g. "Claude Code".
    var reportedBy: String?
    var updated: Date

    /// The device the app supports, if it does.
    func device(_ displayType: ScreenshotDisplayType) -> SupportedDevice? {
        devices.first { $0.displayType == displayType }
    }

    /// The project's languages the App Store page doesn't have yet, in the
    /// project's order, each once.
    func languagesMissing(from storeLocales: [String]) -> [ProjectLanguage] {
        let onStore = Set(storeLocales)
        var seen = Set<String>()
        return languages.filter { language in
            guard let code = language.storeLocale?.code, !onStore.contains(code) else { return false }
            return seen.insert(code).inserted
        }
    }

    /// "targets Lumen (iOS, visionOS) and LumenWatch Watch App, and 15
    /// languages in Localizable.xcstrings, 12 of them on the App Store".
    func foundSummary(storeLocales: [String]) -> String {
        var parts: [String] = []
        if !targets.isEmpty { parts.append(String(localized: "targets \(targets.formatted(.list(type: .and)))")) }
        let languageCount = Set(languages.compactMap { $0.storeLocale?.code }).count
        if languageCount > 0 {
            let onStore = languageCount - languagesMissing(from: storeLocales).count
            let place = languageSource.map { String(localized: "in \($0)") } ?? String(localized: "in the project")
            let languages = languageCount == 1 ? String(localized: "1 language") : String(localized: "\(languageCount) languages")
            let store = languageCount == 1
                ? (onStore == 1 ? String(localized: "on the App Store") : String(localized: "not on the App Store yet"))
                : String(localized: "\(onStore) of them on the App Store")
            parts.append("\(languages) \(place), \(store)")
        }
        // The targets are a list of their own, so the languages follow a comma.
        return parts.count == 2 ? String(localized: "\(parts[0]), and \(parts[1])") : parts.joined()
    }
}
