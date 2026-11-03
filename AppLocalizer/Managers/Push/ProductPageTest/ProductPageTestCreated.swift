//
//  ProductPageTestCreated.swift
//  AppLocalizer
//

import Foundation

/// A test that's in App Store Connect: its IDs, the languages whose
/// variant is on the treatment, the ones that failed and why, and whether
/// it went to App Review.
struct ProductPageTestCreated: Hashable, Sendable {
    var experimentID: String
    var treatmentID: String
    var name: String
    var placement: ProductPageTestPlacement
    var treatmentName: String
    var placedLocales: [String]
    /// Language → why its variant isn't on the treatment.
    var failedLocales: [String: String] = [:]
    var isStarted = false
    /// Why it couldn't be sent to App Review, when it was asked to be.
    var startFailure: String?

    /// "“Header: Interface vs Outcome” is a draft in App Store Connect with
    /// the Outcome header in 12 languages. Start it there…"
    var summary: String {
        let languages = placedLocales.count == 1 ? String(localized: "1 language") : String(localized: "\(placedLocales.count) languages")
        let what = String(localized: "the \(treatmentName) \(placement.title.lowercased()) in \(languages)")
        var text = isStarted
            ? String(localized: "“\(name)” went to App Review with \(what). It runs once it’s approved.")
            : String(localized: "“\(name)” is a draft in App Store Connect with \(what). Start it there when you’ve looked it over.")
        if let startFailure { text += " " + String(localized: "It couldn’t be sent to App Review (\(startFailure)).") }
        if !failedLocales.isEmpty {
            let missing = failedLocales.keys.sorted().formatted(.list(type: .and))
            text += " " + String(localized: "Not on the treatment: \(missing).")
        }
        return text
    }
}
