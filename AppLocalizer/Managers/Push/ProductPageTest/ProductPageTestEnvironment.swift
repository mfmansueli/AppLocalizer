//
//  ProductPageTestEnvironment.swift
//  AppLocalizer
//

import Foundation

/// What a test runs against: the experiment calls, the library uploads,
/// the hourly budget, how a variant's file is read, the clock and how long
/// Apple's processing is waited for. Tests swap every part.
struct ProductPageTestEnvironment {
    var tester: any ProductPageTesting
    var library: any AssetLibraryPushing
    var rate: RequestRateTracker
    /// Whether the variant goes on the treatment through the API. App Store
    /// Connect API 4.5 documents placements on treatment localizations, so
    /// it does; off, the run only exports.
    var placesThroughAPI = ProductPageTestEnvironment.apiPlacesArtworkOnTreatments
    var fileData: @Sendable (URL) async throws -> Data = { try Data(contentsOf: $0, options: .mappedIfSafe) }
    var now: () -> Date = { .now }
    var sleep: @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    var pollInterval: Duration = .seconds(3)
    var longestPollInterval: Duration = .seconds(30)
    var processingTimeout: Duration = .seconds(900)
    var rateLimitRetries = 3

    /// App Store Connect API 4.5.0+ takes an `appStoreVersionExperimentTreatmentLocalization`
    /// on `POST /v1/appAssetLibraryPlacements`, and lists a treatment
    /// localization's placements (4.5.1 release notes, October 2026). It
    /// doesn't say which placement types a treatment takes, so a refusal
    /// still falls back to the export.
    static let apiPlacesArtworkOnTreatments = true
}
