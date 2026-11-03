//
//  ProductPageTestRequest.swift
//  AppLocalizer
//

import Foundation

/// A Product Page Optimization test of one placement: the page as it is
/// (the control, “Interface”) against a variant with one idea changed
/// (the treatment, “Outcome”), in each language the variant was rendered
/// in. A v2 test belongs to the app and its control is the live page, so
/// it takes no version.
struct ProductPageTestRequest: Hashable, Sendable {
    var appID: StoreApp.ID
    var appName: String
    var placement: ProductPageTestPlacement
    /// The test's name in App Store Connect, e.g. "Header: Interface vs Outcome".
    var testName: String
    var controlName = ProductPageTestRequest.defaultControlName
    var treatmentName = ProductPageTestRequest.defaultTreatmentName
    /// The share of the page's visitors who see the treatment, in percent.
    var trafficProportion = 50
    var locales: [ProductPageTestLocale]
    /// Sends the test to App Review once it's made. Off (the default), it
    /// stays a draft and the person starts it in App Store Connect, after
    /// looking at it there.
    var startsTest = false
    /// Where both variants are written when the test can't be made
    /// through the API.
    var exportFolder: URL

    static let defaultControlName = String(localized: "Interface")
    static let defaultTreatmentName = String(localized: "Outcome")
}
