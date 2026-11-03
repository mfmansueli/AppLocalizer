//
//  ProductPageTestStep.swift
//  AppLocalizer
//

import Foundation

/// Where a test is while it's being made. The languages' own progress is
/// in `ProductPageTestRun.localeStatuses`.
enum ProductPageTestStep: Hashable, Sendable {
    case checkingTests
    case creatingTest
    case creatingTreatment
    /// Each language's variant is uploaded and placed on the treatment.
    case placing
    case starting
    /// A draft that couldn't be finished is deleted, so it doesn't block
    /// the next test.
    case removingDraft
    case exporting

    var title: String {
        switch self {
        case .checkingTests: String(localized: "Checking for a test in progress")
        case .creatingTest: String(localized: "Creating the test")
        case .creatingTreatment: String(localized: "Adding the treatment")
        case .placing: String(localized: "Placing the variant in each language")
        case .starting: String(localized: "Sending the test to App Review")
        case .removingDraft: String(localized: "Removing the unfinished draft")
        case .exporting: String(localized: "Exporting both variants")
        }
    }
}
