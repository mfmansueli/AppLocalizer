//
//  AppStoreConnectClientExperimentsTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Product Page Optimization's calls against a fake transport: each one's
/// method, path and JSON:API body, and what's read back. Nothing reaches
/// App Store Connect.
@Suite("AppStoreConnectClient product page experiments")
struct AppStoreConnectClientExperimentsTests {
    private func client(_ transport: FakeHTTPTransport) -> AppStoreConnectClient {
        AppStoreConnectClient(credentials: TestKeys.credentials(), transport: transport)
    }

    private func data(_ request: URLRequest?) throws -> [String: Any] {
        let body = try #require(request?.httpBody)
        let object = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        return try #require(object["data"] as? [String: Any])
    }

    private func relationship(_ name: String, in data: [String: Any]) -> [String: String]? {
        ((data["relationships"] as? [String: Any])?[name] as? [String: Any])?["data"] as? [String: String]
    }

    @Test func listsTheAppsTestsAcrossPages() async throws {
        let first = """
        {"data":[{"type":"appStoreVersionExperiments","id":"exp-1","attributes":{"name":"Icons","platform":"IOS","trafficProportion":30,"state":"COMPLETED"}}],
         "links":{"self":"x","next":"https://api.appstoreconnect.apple.com/v1/apps/123/appStoreVersionExperimentsV2?cursor=2"}}
        """
        let second = #"{"data":[{"type":"appStoreVersionExperiments","id":"exp-2","attributes":{"name":"Header","state":"APPROVED","extra":1}}]}"#
        let transport = FakeHTTPTransport([.init(body: first), .init(body: second)])
        let tests = try await client(transport).productPageExperiments(appID: "123")

        let request = try #require(transport.requests.first)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.path() == "/v1/apps/123/appStoreVersionExperimentsV2")
        #expect(request.url?.query() == "fields%5BappStoreVersionExperiments%5D=name,platform,trafficProportion,state&limit=200")
        #expect(transport.requests.last?.url?.query() == "cursor=2")
        #expect(tests == [
            ProductPageExperiment(id: "exp-1", name: "Icons", platform: "IOS", state: "COMPLETED", trafficProportion: 30),
            ProductPageExperiment(id: "exp-2", name: "Header", state: "APPROVED"),
        ])
        #expect(tests[0].isFinished)
        #expect(!tests[1].isFinished)
        #expect(tests[1].stateTitle == "running")
    }

    @Test func createsADraftTestOnTheAppsIOSPage() async throws {
        let response = """
        {"data":{"type":"appStoreVersionExperiments","id":"exp-9","attributes":{"name":"Header: Interface vs Outcome","state":"PREPARE_FOR_SUBMISSION"}}}
        """
        let transport = FakeHTTPTransport([.init(statusCode: 201, body: response)])
        let test = try await client(transport).createProductPageExperiment(appID: "123", name: "Header: Interface vs Outcome", trafficProportion: 50)

        let request = try #require(transport.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path() == "/v2/appStoreVersionExperiments")
        let data = try data(request)
        #expect(data["type"] as? String == "appStoreVersionExperiments")
        let attributes = try #require(data["attributes"] as? [String: Any])
        #expect(attributes["name"] as? String == "Header: Interface vs Outcome")
        #expect(attributes["platform"] as? String == "IOS")
        #expect(attributes["trafficProportion"] as? Int == 50)
        #expect(relationship("app", in: data) == ["type": "apps", "id": "123"])
        #expect(test.id == "exp-9")
        #expect(test.state == "PREPARE_FOR_SUBMISSION")
    }

    @Test func aSecondDraftIsAStateError() async throws {
        let refusal = """
        {"errors":[{"status":"409","code":"STATE_ERROR","title":"The request cannot be fulfilled because of the state of another resource.",
          "detail":"Cannot create new experiment because another experiment is in draft state"}]}
        """
        let transport = FakeHTTPTransport([.init(statusCode: 409, body: refusal)])
        await #expect {
            _ = try await client(transport).createProductPageExperiment(appID: "123", name: "Header", trafficProportion: 50)
        } throws: { error in
            (error as? AppStoreConnectError)?.isStateError == true
        }
    }

    @Test func addsATreatmentToTheV2Test() async throws {
        let response = #"{"data":{"type":"appStoreVersionExperimentTreatments","id":"tr-1","attributes":{"name":"Outcome"}}}"#
        let transport = FakeHTTPTransport([.init(statusCode: 201, body: response)])
        let treatment = try await client(transport).createProductPageTreatment(experimentID: "exp-9", name: "Outcome")

        let request = try #require(transport.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path() == "/v1/appStoreVersionExperimentTreatments")
        let data = try data(request)
        #expect(data["type"] as? String == "appStoreVersionExperimentTreatments")
        #expect((data["attributes"] as? [String: String]) == ["name": "Outcome"])
        #expect(relationship("appStoreVersionExperimentV2", in: data) == ["type": "appStoreVersionExperiments", "id": "exp-9"])
        #expect(relationship("appStoreVersionExperiment", in: data) == nil)
        #expect(treatment == ProductPageTreatment(id: "tr-1", name: "Outcome"))
    }

    @Test func addsALanguageToTheTreatment() async throws {
        let response = #"{"data":{"type":"appStoreVersionExperimentTreatmentLocalizations","id":"trl-de","attributes":{"locale":"de-DE"}}}"#
        let transport = FakeHTTPTransport([.init(statusCode: 201, body: response)])
        let localization = try await client(transport).createProductPageTreatmentLocalization(treatmentID: "tr-1", locale: "de-DE")

        let request = try #require(transport.requests.first)
        #expect(request.url?.path() == "/v1/appStoreVersionExperimentTreatmentLocalizations")
        let data = try data(request)
        #expect(data["type"] as? String == "appStoreVersionExperimentTreatmentLocalizations")
        #expect((data["attributes"] as? [String: String]) == ["locale": "de-DE"])
        #expect(relationship("appStoreVersionExperimentTreatment", in: data) == ["type": "appStoreVersionExperimentTreatments", "id": "tr-1"])
        #expect(localization == ProductPageTreatmentLocalization(id: "trl-de", locale: "de-DE"))
    }

    @Test func placesTheVariantOnTheTreatmentsPage() async throws {
        let response = """
        {"data":{"type":"appAssetLibraryPlacements","id":"p-1","attributes":{"placementType":"PRODUCT_PAGE_HEADER_ASSET",
          "placementGroup":"PRODUCT_PAGE_HEADER_UNIVERSAL","state":"PARENT_PREPARE_FOR_SUBMISSION"},
          "relationships":{"image":{"data":{"type":"appAssetLibraryImages","id":"img-1"}}}}}
        """
        let transport = FakeHTTPTransport([.init(statusCode: 201, body: response)])
        let placement = try await client(transport).createProductPageTreatmentPlacement(
            placementType: "PRODUCT_PAGE_HEADER_ASSET", placementGroup: "PRODUCT_PAGE_HEADER_UNIVERSAL",
            asset: AssetLibraryAsset(id: "img-1", media: .image), treatmentLocalizationID: "trl-de"
        )

        let request = try #require(transport.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path() == "/v1/appAssetLibraryPlacements")
        let data = try data(request)
        #expect(data["type"] as? String == "appAssetLibraryPlacements")
        #expect((data["attributes"] as? [String: String]) == [
            "placementType": "PRODUCT_PAGE_HEADER_ASSET", "placementGroup": "PRODUCT_PAGE_HEADER_UNIVERSAL",
        ])
        #expect(relationship("image", in: data) == ["type": "appAssetLibraryImages", "id": "img-1"])
        #expect(relationship("appStoreVersionExperimentTreatmentLocalization", in: data) == [
            "type": "appStoreVersionExperimentTreatmentLocalizations", "id": "trl-de",
        ])
        // On the treatment's page, not the live page.
        #expect(relationship("appStoreVersionLocalization", in: data) == nil)
        #expect(placement.id == "p-1")
        #expect(placement.asset == AssetLibraryAsset(id: "img-1", media: .image))
    }

    @Test func startingSetsStarted() async throws {
        let response = #"{"data":{"type":"appStoreVersionExperiments","id":"exp-9","attributes":{"state":"READY_FOR_REVIEW"}}}"#
        let transport = FakeHTTPTransport([.init(body: response)])
        try await client(transport).startProductPageExperiment(id: "exp-9")

        let request = try #require(transport.requests.first)
        #expect(request.httpMethod == "PATCH")
        #expect(request.url?.path() == "/v2/appStoreVersionExperiments/exp-9")
        let data = try data(request)
        #expect(data["id"] as? String == "exp-9")
        #expect(data["type"] as? String == "appStoreVersionExperiments")
        #expect((data["attributes"] as? [String: Bool]) == ["started": true])
    }

    @Test func deletesADraft() async throws {
        let transport = FakeHTTPTransport([.init(statusCode: 204, body: "")])
        try await client(transport).deleteProductPageExperiment(id: "exp-9")

        let request = try #require(transport.requests.first)
        #expect(request.httpMethod == "DELETE")
        #expect(request.url?.path() == "/v2/appStoreVersionExperiments/exp-9")
        #expect(request.httpBody == nil)
    }
}
