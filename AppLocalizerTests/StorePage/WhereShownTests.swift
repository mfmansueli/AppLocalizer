//
//  WhereShownTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Each Store Page field and App Information page says where it shows on
/// the App Store, or that it doesn't.
@Suite("Where it shows")
struct WhereShownTests {
    @Test func storePageFields() {
        #expect(ListingField.subtitle.whereShown(version: "1.4") == "Under the name, on the page and in search results")
        #expect(ListingField.keywords.whereShown(version: "1.4") == "Not shown on the page. Only App Store search reads them")
        #expect(ListingField.whatsNew.whereShown(version: "1.4") == "Under “What’s New”, for version 1.4")
        #expect(ListingField.whatsNew.whereShown(version: nil) == "Under “What’s New”")
        #expect(ListingField.whatsNew.whereShown(version: "") == "Under “What’s New”")
    }

    @Test func appInformationPages() {
        #expect(AppInformationPage.appReview.whereShown(appName: "Lumen") == "Not on the App Store. Only App Review reads it.")
        #expect(AppInformationPage.accessibility.whereShown(appName: "Lumen") == "On the App Store: the Accessibility section lists what Lumen supports.")
        #expect(AppInformationPage.ageRating.whereShown(appName: "Lumen") == "On the App Store: the age under the name, such as 4+.")
    }
}
