//
//  ProductPageTesting.swift
//  AppLocalizer
//

import Foundation

/// The Product Page Optimization calls a header or search results test
/// makes: the app's tests, a new test with its treatment and languages, a
/// library asset placed on the treatment's page, starting it, and deleting
/// a draft that couldn't be finished. The asset's upload goes through
/// `AssetLibraryPushing`. The API client is the real one; tests simulate
/// App Store Connect.
protocol ProductPageTesting: Sendable {
    func productPageExperiments(appID: StoreApp.ID) async throws -> [ProductPageExperiment]
    func createProductPageExperiment(appID: StoreApp.ID, name: String, trafficProportion: Int) async throws -> ProductPageExperiment
    func createProductPageTreatment(experimentID: String, name: String) async throws -> ProductPageTreatment
    func createProductPageTreatmentLocalization(treatmentID: String, locale: String) async throws -> ProductPageTreatmentLocalization
    func createProductPageTreatmentPlacement(
        placementType: String, placementGroup: String, asset: AssetLibraryAsset, treatmentLocalizationID: String
    ) async throws -> AssetLibraryPlacement
    func startProductPageExperiment(id: String) async throws
    func deleteProductPageExperiment(id: String) async throws
}

extension AppStoreConnectClient: ProductPageTesting {}
