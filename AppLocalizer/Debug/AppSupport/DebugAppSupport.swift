//
//  DebugAppSupport.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// What Lumen Journal's Xcode project supports, as Claude Code would
/// report it: iPad, a watch app and visionOS, and its ten App Store
/// languages plus Polish, Turkish and Hebrew, which the App Store page
/// doesn't have yet.
enum DebugAppSupport {
    static let reported = Date(timeIntervalSince1970: 1_793_400_000)

    static let lumen = AppSupportProfile(
        targets: ["Lumen (iOS, visionOS)", "LumenWatch Watch App"],
        devices: [
            SupportedDevice(displayType: .iPad, reason: String(localized: "Lumen runs on iPad")),
            SupportedDevice(displayType: .watch, reason: String(localized: "Lumen has a watch app, LumenWatch")),
            SupportedDevice(displayType: .visionPro, reason: String(localized: "1.4 adds visionOS")),
        ],
        languages: StorePageSampleData.presentLocales.map { ProjectLanguage(code: $0.code, translated: 418, total: 418) } + newLanguages,
        languageSource: "Localizable.xcstrings",
        reportedBy: "Claude Code",
        updated: reported
    )

    /// In the project, not on the App Store.
    static let newLanguages = [
        ProjectLanguage(code: "pl", translated: 412, total: 418),
        ProjectLanguage(code: "tr", translated: 418, total: 418),
        ProjectLanguage(code: "he", translated: 401, total: 418, note: String(localized: "Right to left; tested in LumenUITests")),
    ]

    /// A center that knows Lumen's project, with `declined` said Not Now to.
    @MainActor
    static func center(_ profile: AppSupportProfile = lumen, declined: [String] = []) -> AppSupportCenter {
        let center = AppSupportCenter(profiles: [DebugFixtures.AppID.lumen: profile])
        for code in declined { center.decline(code, for: DebugFixtures.AppID.lumen) }
        return center
    }
}
#endif
