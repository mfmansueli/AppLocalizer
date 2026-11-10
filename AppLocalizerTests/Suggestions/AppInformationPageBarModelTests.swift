//
//  AppInformationPageBarModelTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The bar under an App Information page's title: this page's count, the
/// rest on other pages, and Accept All Pages.
@Suite("App Information page bar")
struct AppInformationPageBarModelTests {
    @Test func thisPageAndTheOthers() {
        let bar = AppInformationPageBarModel(hereCount: 3, totalCount: 10, otherPageCount: 2)
        #expect(bar.acceptHereTitle == "Accept 3 on This Page")
        #expect(bar.acceptAllTitle == "Accept All Pages")
        #expect(bar.restText == "7 more on 2 other pages")
        #expect(bar.acceptAllAccessibilityText == "Accept all pages: 10 suggestions, shows them first")
        #expect(AppInformationPageBarModel(hereCount: 1, totalCount: 2, otherPageCount: 1).restText == "1 more on 1 other page")
    }

    @Test func onlyHereOrNothingAtAll() {
        #expect(AppInformationPageBarModel(hereCount: 4, totalCount: 4, otherPageCount: 0).restText == "Only this page has suggestions")
        let reviewed = AppInformationPageBarModel(hereCount: 0, totalCount: 0, otherPageCount: 0, acceptsRightAway: true)
        #expect(reviewed.acceptAllTitle == "All Pages Reviewed")
        #expect(reviewed.restText == "Every page is reviewed")
        #expect(reviewed.acceptAllAccessibilityText == "Every page is reviewed")
        let right = AppInformationPageBarModel(hereCount: 1, totalCount: 5, otherPageCount: 2, acceptsRightAway: true)
        #expect(right.acceptAllAccessibilityText == "Accept all pages: 5 suggestions, accepts right away")
    }
}
