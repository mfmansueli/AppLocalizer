//
//  PrivacyQuestionnaireTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Apple's questionnaire as AppLocalizer knows it: 35 data types in 16
/// categories, the six purposes, and reading the names assistants, fastlane
/// and privacy manifests use.
@Suite("Privacy questionnaire")
struct PrivacyQuestionnaireTests {
    @Test func thereAre35TypesInEveryCategory() {
        #expect(PrivacyDataType.allCases.count == 35)
        #expect(PrivacyDataCategory.allCases.allSatisfy { !$0.types.isEmpty })
        #expect(PrivacyDataCategory.allCases.flatMap(\.types).count == 35)
        #expect(Set(PrivacyDataType.allCases.map(\.fastlaneKey)).count == 35)
        #expect(Set(PrivacyDataType.allCases.map(\.manifestKey)).count == 35)
    }

    @Test(arguments: ["purchases", "PURCHASE_HISTORY", "NSPrivacyCollectedDataTypePurchaseHistory", "purchase history"])
    func aTypeIsReadFromAnyOfItsNames(name: String) {
        #expect(PrivacyDataType.matching(name) == .purchases)
    }

    @Test func anUnknownTypeIsNil() {
        #expect(PrivacyDataType.matching("fingerprint") == nil)
    }

    @Test(arguments: ["APP_FUNCTIONALITY", "App Functionality", "NSPrivacyCollectedDataTypePurposeAppFunctionality", "app_functionality"])
    func aPurposeIsReadFromAnyOfItsNames(name: String) {
        #expect(PrivacyPurpose.matching(name) == .appFunctionality)
    }

    @Test func anUnknownPurposeSuggestsTheClosest() {
        #expect(PrivacyPurpose.matching("SUPPORT") == nil)
        #expect(PrivacyPurpose.closest(to: "SUPPORT") == .appFunctionality)
        #expect(PrivacyPurpose.closest(to: "MARKETING") == .developersAdvertising)
        #expect(PrivacyPurpose.closest(to: "metrics") == .analytics)
    }

    @Test func aManifestEntryDeclaresItsType() {
        let evidence = PrivacyEvidence(kind: .sdkManifest, sdk: "RevenueCat", version: "5.14.2", entry: "NSPrivacyCollectedDataTypePurchaseHistory")
        #expect(evidence.declaredType == .purchases)
        #expect(evidence.sdkName == "RevenueCat 5.14.2")
        #expect(evidence.reference == "RevenueCat 5.14.2 · NSPrivacyCollectedDataTypePurchaseHistory")
        let code = PrivacyEvidence(kind: .code, path: "Lumen/Paywall/PaywallModel.swift", line: 88)
        #expect(code.declaredType == nil)
        #expect(code.reference == "Lumen/Paywall/PaywallModel.swift:88")
    }

    @Test func confidenceIsOrderedAndHasBars() {
        #expect(PrivacyConfidence.low < .high)
        #expect(PrivacyConfidence.allCases.map(\.bars) == [1, 2, 3])
    }
}
