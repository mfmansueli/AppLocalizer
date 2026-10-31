//
//  NewLanguagesFixtures.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// The fixture app's project as its assistant reported it: English and
/// German, which the App Store page has, and Polish, Turkish and Hebrew,
/// which it doesn't.
@MainActor
enum NewLanguagesFixtures {
    static let appID = StorePageContentFixtures.app.id

    static let profile = AppSupportProfile(
        languages: [
            ProjectLanguage(code: "en", translated: 418, total: 418),
            ProjectLanguage(code: "de", translated: 418, total: 418),
            ProjectLanguage(code: "pl", translated: 412, total: 418),
            ProjectLanguage(code: "tr", translated: 418, total: 418),
            ProjectLanguage(code: "he", translated: 401, total: 418, note: "Right to left; tested in LumenUITests"),
        ],
        languageSource: "Localizable.xcstrings",
        reportedBy: "Claude Code",
        updated: Date(timeIntervalSince1970: 1_800_000_000)
    )

    static func center(declined: [String] = []) -> AppSupportCenter {
        let center = AppSupportCenter(profiles: [appID: profile])
        for code in declined { center.decline(code, for: appID) }
        return center
    }

    static func services(_ center: AppSupportCenter = center(), contents: [StorePageContent]? = nil) -> FakeStorePageServices {
        let services = contents.map { FakeStorePageServices(contents: $0) } ?? FakeStorePageServices()
        services.appSupport = center
        return services
    }
}
