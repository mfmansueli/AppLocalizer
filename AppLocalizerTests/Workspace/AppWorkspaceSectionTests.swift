//
//  AppWorkspaceSectionTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

/// The workspace's five sections: Screenshots on ⌘4 before App
/// Information, and Pricing shortened only in the toolbar.
@Suite("AppWorkspaceSection")
struct AppWorkspaceSectionTests {
    @Test func screenshotsComesBeforeAppInformation() {
        #expect(AppWorkspaceSection.allCases == [.overview, .subscriptionPricing, .storePage, .screenshots, .appInformation])
        #expect(AppWorkspaceSection.screenshots.shortcutDigit == "4")
        #expect(AppWorkspaceSection.appInformation.shortcutDigit == "5")
    }

    @Test func pricingIsShortenedOnlyInTheToolbar() {
        #expect(AppWorkspaceSection.subscriptionPricing.title == "Pricing")
        #expect(AppWorkspaceSection.subscriptionPricing.fullTitle == "Subscription Pricing")
    }

    @Test(arguments: [
        (AppWorkspaceSection.overview, "Overview"),
        (.storePage, "Store Page"),
        (.screenshots, "Screenshots"),
        (.appInformation, "App Information"),
    ])
    func theOtherSectionsUseOneName(section: AppWorkspaceSection, title: String) {
        #expect(section.title == title)
        #expect(section.fullTitle == title)
    }

    @Test func everySectionHasItsOwnSymbol() {
        let symbols = AppWorkspaceSection.allCases.map(\.systemImage)
        #expect(Set(symbols).count == symbols.count)
        #expect(AppWorkspaceSection.screenshots.systemImage == "photo.on.rectangle")
    }
}
