//
//  CountingPricingServices.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// Answers every app with `summary`, or throws `error`; counts the fetches.
@MainActor
final class CountingPricingServices: PricingServices {
    var summary = PricingSummary.empty
    var error: (any Error)?
    private(set) var fetches = 0

    func summary(for _: StoreApp) async throws -> PricingSummary {
        fetches += 1
        if let error { throw error }
        return summary
    }
}
