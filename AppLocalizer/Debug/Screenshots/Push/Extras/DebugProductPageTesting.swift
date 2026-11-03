//
//  DebugProductPageTesting.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Product Page Optimization for DEBUG scenes: no test in progress, a
/// draft made at once, and (when the script says so) a treatment that
/// won't take the artwork, like an API that doesn't allow it there, so the
/// test falls back to the export. Never contacts App Store Connect.
final class DebugProductPageTesting: ProductPageTesting {
    private let script: DebugExtrasScript

    init(script: DebugExtrasScript) {
        self.script = script
    }

    func productPageExperiments(appID _: StoreApp.ID) async throws -> [ProductPageExperiment] { [] }

    func createProductPageExperiment(appID _: StoreApp.ID, name: String, trafficProportion: Int) async throws -> ProductPageExperiment {
        try await Task.sleep(for: script.delay)
        return ProductPageExperiment(id: "debug-test", name: name, platform: "IOS", state: "PREPARE_FOR_SUBMISSION", trafficProportion: trafficProportion)
    }

    func createProductPageTreatment(experimentID _: String, name: String) async throws -> ProductPageTreatment {
        ProductPageTreatment(id: "debug-treatment", name: name)
    }

    func createProductPageTreatmentLocalization(treatmentID _: String, locale: String) async throws -> ProductPageTreatmentLocalization {
        ProductPageTreatmentLocalization(id: "debug-treatment-\(locale)", locale: locale)
    }

    func createProductPageTreatmentPlacement(
        placementType: String, placementGroup: String, asset: AssetLibraryAsset, treatmentLocalizationID: String
    ) async throws -> AssetLibraryPlacement {
        try await Task.sleep(for: script.delay)
        if script.refusesTreatmentArtwork {
            throw AppStoreConnectError.rejected(
                statusCode: 409, code: "ENTITY_ERROR.RELATIONSHIP.INVALID", detail: "This placement type isn’t allowed on a treatment"
            )
        }
        return AssetLibraryPlacement(id: "debug-\(treatmentLocalizationID)", placementType: placementType, placementGroup: placementGroup, asset: asset)
    }

    func startProductPageExperiment(id _: String) async throws {}

    func deleteProductPageExperiment(id _: String) async throws {}
}
#endif
