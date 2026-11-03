//
//  ProductPageExperimentRequests.swift
//  AppLocalizer
//

import Foundation

/// Product Page Optimization's requests (`appStoreVersionExperiments` v2,
/// their treatments and treatment localizations) and what's read from
/// their responses. A v2 test belongs to the app: its control is the live
/// page. Since API 4.5 a treatment localization takes App Asset Library
/// placements, the header and search results artwork among them.
enum ProductPageExperimentRequests {
    /// The platform every test here is for.
    static let platform = "IOS"

    /// `GET /v1/apps/{id}/appStoreVersionExperimentsV2`: the app's tests,
    /// finished ones too.
    static func experimentsPath(appID: StoreApp.ID) -> String {
        "/v1/apps/\(appID)/appStoreVersionExperimentsV2?fields%5BappStoreVersionExperiments%5D="
            + "name,platform,trafficProportion,state&limit=200"
    }

    /// `POST /v2/appStoreVersionExperiments`: a draft test with no
    /// treatment yet. `trafficProportion` is the share of the page's
    /// visitors who see a treatment, in percent.
    static func createExperiment(appID: StoreApp.ID, name: String, trafficProportion: Int) -> PushRequest {
        request(.post, "/v2/appStoreVersionExperiments", [
            "data": [
                "type": "appStoreVersionExperiments",
                "attributes": ["name": name, "platform": platform, "trafficProportion": trafficProportion],
                "relationships": ["app": ["data": ["type": "apps", "id": appID]]],
            ],
        ])
    }

    /// `POST /v1/appStoreVersionExperimentTreatments` on a v2 test.
    static func createTreatment(experimentID: String, name: String) -> PushRequest {
        request(.post, "/v1/appStoreVersionExperimentTreatments", [
            "data": [
                "type": "appStoreVersionExperimentTreatments",
                "attributes": ["name": name],
                "relationships": [
                    "appStoreVersionExperimentV2": ["data": ["type": "appStoreVersionExperiments", "id": experimentID]],
                ],
            ],
        ])
    }

    /// `POST /v1/appStoreVersionExperimentTreatmentLocalizations`: the
    /// treatment's page in `locale`, e.g. `de-DE`.
    static func createTreatmentLocalization(treatmentID: String, locale: String) -> PushRequest {
        request(.post, "/v1/appStoreVersionExperimentTreatmentLocalizations", [
            "data": [
                "type": "appStoreVersionExperimentTreatmentLocalizations",
                "attributes": ["locale": locale],
                "relationships": [
                    "appStoreVersionExperimentTreatment": ["data": ["type": "appStoreVersionExperimentTreatments", "id": treatmentID]],
                ],
            ],
        ])
    }

    /// `POST /v1/appAssetLibraryPlacements` on a treatment's page.
    static func createTreatmentPlacement(
        placementType: String, placementGroup: String, asset: AssetLibraryAsset, treatmentLocalizationID: String
    ) -> PushRequest {
        request(.post, "/v1/appAssetLibraryPlacements", [
            "data": [
                "type": "appAssetLibraryPlacements",
                "attributes": ["placementType": placementType, "placementGroup": placementGroup],
                "relationships": [
                    asset.media.relationship: ["data": ["type": asset.media.resourceType, "id": asset.id]],
                    "appStoreVersionExperimentTreatmentLocalization": [
                        "data": ["type": "appStoreVersionExperimentTreatmentLocalizations", "id": treatmentLocalizationID],
                    ],
                ],
            ],
        ])
    }

    /// `PATCH /v2/appStoreVersionExperiments/{id}` with `started`: sends
    /// the test to App Review, and it runs once approved.
    static func startExperiment(id: String) -> PushRequest {
        request(.patch, "/v2/appStoreVersionExperiments/\(id)", [
            "data": ["type": "appStoreVersionExperiments", "id": id, "attributes": ["started": true]],
        ])
    }

    /// `DELETE /v2/appStoreVersionExperiments/{id}`: a draft that couldn't
    /// be finished, so it doesn't block the next test.
    static func deleteExperiment(id: String) -> PushRequest {
        PushRequest(method: .delete, path: "/v2/appStoreVersionExperiments/\(id)", body: nil)
    }

    // MARK: - Responses

    static func experiments(in data: Data) throws -> (experiments: [ProductPageExperiment], next: URL?) {
        do {
            let page = try JSONDecoder().decode(
                ScreenshotAPIDocument<ProductPageExperimentAttributes, ProductPageExperimentAttributes>.self, from: data
            )
            return (page.data.map(ProductPageExperiment.init), page.links?.next)
        } catch {
            throw AppStoreConnectError.unexpectedPayload
        }
    }

    static func experiment(in data: Data) throws -> ProductPageExperiment {
        try ProductPageExperiment(resource(ProductPageExperimentAttributes.self, in: data))
    }

    static func treatment(in data: Data) throws -> ProductPageTreatment {
        try ProductPageTreatment(resource(ProductPageTreatmentAttributes.self, in: data))
    }

    static func treatmentLocalization(in data: Data) throws -> ProductPageTreatmentLocalization {
        try ProductPageTreatmentLocalization(resource(ProductPageTreatmentLocaleAttributes.self, in: data))
    }

    // MARK: - Helpers

    private static func resource<Attributes: Decodable & Sendable>(
        _: Attributes.Type, in data: Data
    ) throws -> ScreenshotAPIResource<Attributes> {
        do {
            return try JSONDecoder().decode(ScreenshotAPISingleDocument<Attributes>.self, from: data).data
        } catch {
            throw AppStoreConnectError.unexpectedPayload
        }
    }

    private static func request(_ method: PushRequest.Method, _ path: String, _ object: [String: Any]) -> PushRequest {
        let body = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .withoutEscapingSlashes])
        return PushRequest(method: method, path: path, body: body)
    }
}
