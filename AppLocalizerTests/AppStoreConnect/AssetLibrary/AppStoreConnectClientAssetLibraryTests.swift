//
//  AppStoreConnectClientAssetLibraryTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The App Asset Library calls against a fake transport: each one's
/// method, path, query and JSON:API body, and what's read back. Nothing
/// reaches App Store Connect.
@Suite("AppStoreConnectClient asset library")
struct AppStoreConnectClientAssetLibraryTests {
    private func client(_ transport: FakeHTTPTransport) -> AppStoreConnectClient {
        AppStoreConnectClient(credentials: TestKeys.credentials(), transport: transport)
    }

    /// The request's body as a JSON object.
    private func body(_ request: URLRequest?) throws -> [String: Any] {
        let data = try #require(request?.httpBody)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func resource(_ object: [String: Any]) -> [String: Any] {
        object["data"] as? [String: Any] ?? [:]
    }

    @Test func readsTheAppsLibrary() async throws {
        let transport = FakeHTTPTransport([.init(body: #"{"data":{"type":"appAssetLibraries","id":"lib-1"}}"#)])
        let id = try await client(transport).assetLibraryID(appID: "123")

        let request = try #require(transport.requests.first)
        #expect(id == "lib-1")
        #expect(request.httpMethod == "GET")
        #expect(request.url?.absoluteString == "https://api.appstoreconnect.apple.com/v1/apps/123/assetLibrary")
        #expect(request.value(forHTTPHeaderField: "Authorization")?.hasPrefix("Bearer ") == true)
    }

    @Test func readsTheReferenceData() async throws {
        let transport = FakeHTTPTransport([.init(body: AssetLibraryRefDataSample.json)])
        let refData = try await client(transport).assetLibraryRefData()

        let request = try #require(transport.requests.first)
        #expect(request.url?.path() == "/v1/appAssetLibraryRefData")
        #expect(request.url?.query() == "fields%5BappAssetLibraryRefData%5D=features,placementProfileGroups,imageSpecs,videoSpecs,placementTypes")
        #expect(refData == AssetLibraryRefDataSample.refData)
    }

    @Test func reservesAnImageInTheLibrary() async throws {
        let response = """
        {"data":{"type":"appAssetLibraryImages","id":"img-1","attributes":{"state":"AWAITING_UPLOAD","uploadOperations":[
          {"method":"PUT","url":"https://upload.example/img-1/1","offset":0,"length":6,"requestHeaders":[{"name":"Content-Type","value":"image/png"}]},
          {"method":"PUT","url":"https://upload.example/img-1/2","offset":6,"length":6,"expiration":"2026-11-02T20:00:00Z"}
        ]}}}
        """
        let transport = FakeHTTPTransport([.init(statusCode: 201, body: response)])
        let reservation = try await client(transport).reserveAssetLibraryImage(
            libraryID: "lib-1", fileName: "de-DE-header.png", fileSize: 12, category: "CREATIVE_ASSETS", referenceName: "Autopilot · de-DE · Header"
        )

        let request = try #require(transport.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path() == "/v1/appAssetLibraryImages")
        let data = try resource(body(request))
        #expect(data["type"] as? String == "appAssetLibraryImages")
        let attributes = try #require(data["attributes"] as? [String: Any])
        #expect(attributes["fileName"] as? String == "de-DE-header.png")
        #expect(attributes["fileSize"] as? Int == 12)
        #expect(attributes["category"] as? String == "CREATIVE_ASSETS")
        #expect(attributes["referenceName"] as? String == "Autopilot · de-DE · Header")
        #expect(attributes["previewFrameTimeCode"] == nil)
        let library = (data["relationships"] as? [String: Any])?["assetLibrary"] as? [String: Any]
        #expect(library?["data"] as? [String: String] == ["type": "appAssetLibraries", "id": "lib-1"])

        #expect(reservation.asset == AssetLibraryAsset(id: "img-1", media: .image))
        #expect(reservation.uploadOperations.map(\.offset) == [0, 6])
        #expect(reservation.uploadOperations.first?.requestHeaders?.first?.value == "image/png")
    }

    @Test func reservesAVideoWithItsPosterFrame() async throws {
        let transport = FakeHTTPTransport([.init(statusCode: 201, body: #"{"data":{"type":"appAssetLibraryVideos","id":"vid-1","attributes":{}}}"#)])
        let reservation = try await client(transport).reserveAssetLibraryVideo(
            libraryID: "lib-1", fileName: "en-US-preview.mov", fileSize: 4096, category: "APP_SCREENSHOTS_AND_PREVIEWS",
            referenceName: "Autopilot · en-US · App Preview", previewFrameTimeCode: "00:00:05:00"
        )

        let request = try #require(transport.requests.first)
        #expect(request.url?.path() == "/v1/appAssetLibraryVideos")
        let data = try resource(body(request))
        #expect(data["type"] as? String == "appAssetLibraryVideos")
        let attributes = try #require(data["attributes"] as? [String: Any])
        #expect(attributes["previewFrameTimeCode"] as? String == "00:00:05:00")
        #expect(attributes["category"] as? String == "APP_SCREENSHOTS_AND_PREVIEWS")
        #expect(reservation.asset == AssetLibraryAsset(id: "vid-1", media: .video))
        #expect(reservation.uploadOperations.isEmpty)
    }

    @Test func partsGoToTheUploadHostWithoutTheAPIToken() async throws {
        let transport = FakeHTTPTransport([.init(body: "")])
        let library: any AssetLibraryPushing = client(transport)
        let operation = ScreenshotUploadOperation(
            method: "PUT", url: "https://upload.example/img-1/2", offset: 4, length: 4,
            requestHeaders: [ScreenshotUploadHeader(name: "Content-Type", value: "image/png")]
        )
        try await library.upload(operation, data: Data("0123456789ab".utf8)) { _ in }

        let request = try #require(transport.requests.first)
        #expect(request.httpMethod == "PUT")
        #expect(request.url?.absoluteString == "https://upload.example/img-1/2")
        #expect(request.httpBody == Data("4567".utf8))
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "image/png")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test func committingSaysEveryPartIsUp() async throws {
        let transport = FakeHTTPTransport([.init(body: #"{"data":{"type":"appAssetLibraryImages","id":"img-1"}}"#)])
        try await client(transport).commitAssetLibraryAsset(AssetLibraryAsset(id: "img-1", media: .image))

        let request = try #require(transport.requests.first)
        #expect(request.httpMethod == "PATCH")
        #expect(request.url?.path() == "/v1/appAssetLibraryImages/img-1")
        let data = try resource(body(request))
        #expect(data["type"] as? String == "appAssetLibraryImages")
        #expect(data["id"] as? String == "img-1")
        #expect(data["attributes"] as? [String: Bool] == ["uploaded": true])
    }

    @Test func aFailedStateCarriesApplesDetails() async throws {
        let response = """
        {"data":{"type":"appAssetLibraryVideos","id":"vid-1","attributes":{"state":"FAILED","stateDetails":[
          {"code":"VIDEO_INCORRECT_FRAME_RATE","description":"The video is 60 fps"},{"code":"VIDEO_AUDIO_MISSING"}
        ]}}}
        """
        let transport = FakeHTTPTransport([.init(body: response)])
        let status = try await client(transport).assetLibraryAssetState(AssetLibraryAsset(id: "vid-1", media: .video))

        let request = try #require(transport.requests.first)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.path() == "/v1/appAssetLibraryVideos/vid-1")
        #expect(request.url?.query() == "fields%5BappAssetLibraryVideos%5D=state,stateDetails")
        #expect(status.isFailed)
        #expect(!status.isReady)
        #expect(status.detailText == "VIDEO_INCORRECT_FRAME_RATE — The video is 60 fps; VIDEO_AUDIO_MISSING")
    }

    @Test func statesAreReadLeniently() async throws {
        let transport = FakeHTTPTransport([
            .init(body: #"{"data":{"type":"appAssetLibraryImages","id":"a","attributes":{"state":"PREPARE_FOR_SUBMISSION"}}}"#),
            .init(body: """
            {"data":{"type":"appAssetLibraryImages","id":"b","attributes":{"state":"UPLOAD_COMPLETE","stateDetails":{"errors":[{"code":"X"}]}}}}
            """),
            .init(body: #"{"data":{"type":"appAssetLibraryImages","id":"c","attributes":{"state":7,"stateDetails":"none"}}}"#),
        ])
        let api = client(transport)
        let ready = try await api.assetLibraryAssetState(AssetLibraryAsset(id: "a", media: .image))
        let processing = try await api.assetLibraryAssetState(AssetLibraryAsset(id: "b", media: .image))
        let odd = try await api.assetLibraryAssetState(AssetLibraryAsset(id: "c", media: .image))

        #expect(ready.isReady)
        #expect(!processing.isReady && !processing.isFailed)
        #expect(processing.detailText == "X")
        #expect(odd == AssetLibraryAssetStatus(state: nil))
    }

    @Test func listsAGroupsPlacementsInOrderAcrossPages() async throws {
        let first = """
        {"data":[
          {"type":"appAssetLibraryPlacements","id":"p-1","attributes":{"placementType":"APP_PREVIEW","placementGroup":"IPHONE","state":"PARENT_APPROVED"},
           "relationships":{"video":{"data":{"type":"appAssetLibraryVideos","id":"vid-1"}},"image":{"data":null}}},
          {"type":"appAssetLibraryPlacements","id":"p-2","attributes":{"placementType":"APP_PREVIEW","placementGroup":"IPHONE"}}
        ],
        "included":[{"type":"appAssetLibraryVideos","id":"vid-1","attributes":{"state":"APPROVED"}}],
        "links":{"self":"https://api.appstoreconnect.apple.com/v1/x","next":"https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/loc-de/placements?cursor=Mg"}}
        """
        let second = """
        {"data":[{"type":"appAssetLibraryPlacements","id":"p-3","relationships":{"image":{"data":{"type":"appAssetLibraryImages","id":"img-3"}}}}],
         "links":{"self":"https://api.appstoreconnect.apple.com/v1/y"}}
        """
        let transport = FakeHTTPTransport([.init(body: first), .init(body: second)])
        let placements = try await client(transport).assetLibraryPlacements(localizationID: "loc-de", placementType: "APP_PREVIEW", placementGroup: "IPHONE")

        let request = try #require(transport.requests.first)
        #expect(request.url?.path() == "/v1/appStoreVersionLocalizations/loc-de/placements")
        #expect(request.url?.query() == "filter%5BplacementType%5D=APP_PREVIEW&filter%5BplacementGroup%5D=IPHONE"
            + "&sort=placementGroupPosition&include=image,video&limit=200")
        #expect(transport.requests.last?.url?.query() == "cursor=Mg")
        #expect(placements.map(\.id) == ["p-1", "p-2", "p-3"])
        #expect(placements.map(\.asset) == [
            AssetLibraryAsset(id: "vid-1", media: .video), nil, AssetLibraryAsset(id: "img-3", media: .image),
        ])
        #expect(placements.first?.state == "PARENT_APPROVED")
        #expect(placements.first?.placementGroup == "IPHONE")
    }

    @Test func createsAPlacementOnTheLocalization() async throws {
        let response = """
        {"data":{"type":"appAssetLibraryPlacements","id":"p-9",
          "attributes":{"placementType":"APP_PREVIEW","placementGroup":"IPHONE","state":"ASSET_PROCESSING"}}}
        """
        let transport = FakeHTTPTransport([.init(statusCode: 201, body: response)])
        let placement = try await client(transport).createAssetLibraryPlacement(
            placementType: "APP_PREVIEW", placementGroup: "IPHONE", asset: AssetLibraryAsset(id: "vid-1", media: .video), localizationID: "loc-de"
        )

        let request = try #require(transport.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path() == "/v1/appAssetLibraryPlacements")
        let data = try resource(body(request))
        #expect(data["type"] as? String == "appAssetLibraryPlacements")
        #expect(data["attributes"] as? [String: String] == ["placementType": "APP_PREVIEW", "placementGroup": "IPHONE"])
        let relationships = try #require(data["relationships"] as? [String: [String: [String: String]]])
        #expect(relationships["video"]?["data"] == ["type": "appAssetLibraryVideos", "id": "vid-1"])
        #expect(relationships["appStoreVersionLocalization"]?["data"] == ["type": "appStoreVersionLocalizations", "id": "loc-de"])
        #expect(relationships["image"] == nil)
        #expect(placement == AssetLibraryPlacement(id: "p-9", placementType: "APP_PREVIEW", placementGroup: "IPHONE", state: "ASSET_PROCESSING"))
    }

    @Test func deletesAPlacement() async throws {
        let transport = FakeHTTPTransport([.init(statusCode: 204, body: "")])
        try await client(transport).deleteAssetLibraryPlacement(id: "p-1")

        let request = try #require(transport.requests.first)
        #expect(request.httpMethod == "DELETE")
        #expect(request.url?.path() == "/v1/appAssetLibraryPlacements/p-1")
        #expect(request.httpBody == nil)
    }

    @Test func ordersAGroupsPlacements() async throws {
        let transport = FakeHTTPTransport([.init(statusCode: 201, body: #"{"data":{"type":"appAssetLibraryPlacementOrderingRequests","id":"o-1"}}"#)])
        try await client(transport).orderAssetLibraryPlacements(["p-9", "p-1"], placementGroup: "IPHONE", localizationID: "loc-de")

        let request = try #require(transport.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path() == "/v1/appAssetLibraryPlacementOrderingRequests")
        let data = try resource(body(request))
        #expect(data["type"] as? String == "appAssetLibraryPlacementOrderingRequests")
        #expect(data["attributes"] as? [String: String] == ["placementGroup": "IPHONE"])
        let relationships = try #require(data["relationships"] as? [String: Any])
        let ordered = (relationships["orderedPlacements"] as? [String: Any])?["data"] as? [[String: String]]
        #expect(ordered == [["type": "appAssetLibraryPlacements", "id": "p-9"], ["type": "appAssetLibraryPlacements", "id": "p-1"]])
        let localization = (relationships["appStoreVersionLocalization"] as? [String: Any])?["data"] as? [String: String]
        #expect(localization == ["type": "appStoreVersionLocalizations", "id": "loc-de"])
    }

    @Test func refusalsCarryApplesCodeAndDetail() async {
        let body = #"{"errors":[{"status":"409","code":"STATE_ERROR.INVALID_STATE","title":"Invalid state","detail":"The version can’t be edited."}]}"#
        let transport = FakeHTTPTransport([.init(statusCode: 409, body: body)])
        let expected = AppStoreConnectError.rejected(statusCode: 409, code: "STATE_ERROR.INVALID_STATE", detail: "The version can’t be edited.")
        await #expect(throws: expected) {
            try await client(transport).createAssetLibraryPlacement(
                placementType: "PRODUCT_PAGE_HEADER_ASSET", placementGroup: "G", asset: AssetLibraryAsset(id: "img-1", media: .image), localizationID: "loc"
            )
        }
    }

    @Test func aMissingLibraryIsNotFound() async {
        let transport = FakeHTTPTransport([.init(statusCode: 404, body: #"{"errors":[{"status":"404","code":"NOT_FOUND","detail":"No asset library."}]}"#)])
        await #expect(throws: AppStoreConnectError.notFound(detail: "No asset library.")) {
            try await client(transport).assetLibraryID(appID: "123")
        }
    }
}
