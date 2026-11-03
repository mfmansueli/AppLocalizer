//
//  FakeProductPageTesting.swift
//  AppLocalizerTests
//

import Foundation
import Synchronization
@testable import AppLocalizer

/// Answers Product Page Optimization's calls like App Store Connect would
/// and logs each one in order (`tests app-1`, `create Header test 50`,
/// `treatment exp-1 Outcome`, `locale tr-1 de-DE`,
/// `place image-3 PRODUCT_PAGE_HEADER_ASSET … trl-de-DE`, `start exp-1`,
/// `delete exp-1`). It can refuse artwork on a treatment, like an API that
/// doesn't take it there. Nothing reaches the network.
final class FakeProductPageTesting: ProductPageTesting {
    struct Script: Sendable {
        /// What the app's test list shows.
        var tests: [ProductPageExperiment] = []
        /// Creating a test gets 409 `STATE_ERROR`.
        var refusesNewTest = false
        /// Placements on these languages' treatment pages are refused, as
        /// Apple would for a placement type a treatment doesn't take.
        var refusedLocales: Set<String> = []
        var deleteFails = false
        var startFails = false
    }

    private let script: Script
    private let state = Mutex<[String]>([])

    init(_ script: Script = Script()) {
        self.script = script
    }

    var log: [String] { state.withLock { $0 } }

    private func log(_ entry: String) {
        state.withLock { $0.append(entry) }
    }

    func productPageExperiments(appID: StoreApp.ID) async throws -> [ProductPageExperiment] {
        log("tests \(appID)")
        return script.tests
    }

    func createProductPageExperiment(appID _: StoreApp.ID, name: String, trafficProportion: Int) async throws -> ProductPageExperiment {
        log("create \(name) \(trafficProportion)")
        if script.refusesNewTest {
            throw AppStoreConnectError.rejected(
                statusCode: 409, code: "STATE_ERROR", detail: "Cannot create new experiment because another experiment is in draft state"
            )
        }
        return ProductPageExperiment(id: "exp-1", name: name, platform: "IOS", state: "PREPARE_FOR_SUBMISSION", trafficProportion: trafficProportion)
    }

    func createProductPageTreatment(experimentID: String, name: String) async throws -> ProductPageTreatment {
        log("treatment \(experimentID) \(name)")
        return ProductPageTreatment(id: "tr-1", name: name)
    }

    func createProductPageTreatmentLocalization(treatmentID: String, locale: String) async throws -> ProductPageTreatmentLocalization {
        log("locale \(treatmentID) \(locale)")
        return ProductPageTreatmentLocalization(id: "trl-\(locale)", locale: locale)
    }

    func createProductPageTreatmentPlacement(
        placementType: String, placementGroup: String, asset: AssetLibraryAsset, treatmentLocalizationID: String
    ) async throws -> AssetLibraryPlacement {
        log("place \(asset.id) \(placementType) \(placementGroup) \(treatmentLocalizationID)")
        if script.refusedLocales.contains(where: { treatmentLocalizationID == "trl-\($0)" }) {
            throw AppStoreConnectError.rejected(
                statusCode: 409, code: "ENTITY_ERROR.RELATIONSHIP.INVALID", detail: "This placement type isn’t allowed here"
            )
        }
        return AssetLibraryPlacement(id: "pl-\(treatmentLocalizationID)", placementType: placementType, placementGroup: placementGroup, asset: asset)
    }

    func startProductPageExperiment(id: String) async throws {
        log("start \(id)")
        if script.startFails {
            throw AppStoreConnectError.rejected(statusCode: 409, code: "STATE_ERROR", detail: "The treatment has no screenshots")
        }
    }

    func deleteProductPageExperiment(id: String) async throws {
        log("delete \(id)")
        if script.deleteFails { throw AppStoreConnectError.server(statusCode: 500, detail: "Try again later") }
    }
}
