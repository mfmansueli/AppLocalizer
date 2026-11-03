//
//  AppStoreConnectClient+Experiments.swift
//  AppLocalizer
//

import Foundation

/// Product Page Optimization: the app's tests, a new test with one
/// treatment and its languages, a library asset placed on a treatment's
/// page, and starting the test. The asset's upload is the App Asset
/// Library's (`AppStoreConnectClient+AssetLibrary`).
extension AppStoreConnectClient {
    /// The most pages of tests read; an app has a few.
    private static let experimentPageLimit = 5

    /// Every test the app has had, finished ones too.
    func productPageExperiments(appID: StoreApp.ID) async throws -> [ProductPageExperiment] {
        var path: String? = ProductPageExperimentRequests.experimentsPath(appID: appID)
        var experiments: [ProductPageExperiment] = []
        var pages = 0
        while let next = path, pages < Self.experimentPageLimit {
            let page = try await ProductPageExperimentRequests.experiments(in: fetch(next).data)
            experiments += page.experiments
            path = page.next?.absoluteString
            pages += 1
        }
        return experiments
    }

    /// A draft test on the app's iOS page.
    func createProductPageExperiment(appID: StoreApp.ID, name: String, trafficProportion: Int) async throws -> ProductPageExperiment {
        let request = ProductPageExperimentRequests.createExperiment(appID: appID, name: name, trafficProportion: trafficProportion)
        return try await ProductPageExperimentRequests.experiment(in: send(request).data)
    }

    func createProductPageTreatment(experimentID: String, name: String) async throws -> ProductPageTreatment {
        let request = ProductPageExperimentRequests.createTreatment(experimentID: experimentID, name: name)
        return try await ProductPageExperimentRequests.treatment(in: send(request).data)
    }

    func createProductPageTreatmentLocalization(treatmentID: String, locale: String) async throws -> ProductPageTreatmentLocalization {
        let request = ProductPageExperimentRequests.createTreatmentLocalization(treatmentID: treatmentID, locale: locale)
        return try await ProductPageExperimentRequests.treatmentLocalization(in: send(request).data)
    }

    /// Shows `asset` on the treatment's page in one language, e.g. as its
    /// product page header.
    func createProductPageTreatmentPlacement(
        placementType: String, placementGroup: String, asset: AssetLibraryAsset, treatmentLocalizationID: String
    ) async throws -> AssetLibraryPlacement {
        let request = ProductPageExperimentRequests.createTreatmentPlacement(
            placementType: placementType, placementGroup: placementGroup, asset: asset, treatmentLocalizationID: treatmentLocalizationID
        )
        return try await AssetLibraryRequests.placement(in: send(request).data)
    }

    /// Sends the test to App Review; it runs once approved.
    func startProductPageExperiment(id: String) async throws {
        _ = try await send(ProductPageExperimentRequests.startExperiment(id: id))
    }

    /// Deletes a draft test.
    func deleteProductPageExperiment(id: String) async throws {
        _ = try await send(ProductPageExperimentRequests.deleteExperiment(id: id))
    }
}
