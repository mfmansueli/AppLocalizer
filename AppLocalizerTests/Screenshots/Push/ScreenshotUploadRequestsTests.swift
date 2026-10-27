//
//  ScreenshotUploadRequestsTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The screenshot endpoints' requests and responses, and the API client
/// sending a part to Apple's upload host. Nothing reaches Apple.
@Suite("ScreenshotUploadRequests")
struct ScreenshotUploadRequestsTests {
    private func json(_ request: PushRequest) throws -> [String: Any] {
        let body = try #require(request.body)
        return try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
    }

    @Test func createSetNamesTheDisplayTypeAndLocalization() throws {
        let request = ScreenshotUploadRequests.createSet(displayType: .iPad, localizationID: "loc-de")
        #expect(request.method == .post)
        #expect(request.path == "/v1/appScreenshotSets")
        let data = try #require(try json(request)["data"] as? [String: Any])
        #expect((data["attributes"] as? [String: Any])?["screenshotDisplayType"] as? String == "APP_IPAD_PRO_3GEN_129")
        let localization = (data["relationships"] as? [String: Any])?["appStoreVersionLocalization"] as? [String: Any]
        #expect((localization?["data"] as? [String: Any])?["id"] as? String == "loc-de")
    }

    @Test func reserveCommitDeleteAndReorder() throws {
        let reserve = try json(ScreenshotUploadRequests.reserve(fileName: "a.png", fileSize: 1234, setID: "set-1"))
        let attributes = (reserve["data"] as? [String: Any])?["attributes"] as? [String: Any]
        #expect(attributes?["fileSize"] as? Int == 1234)
        #expect(attributes?["fileName"] as? String == "a.png")

        let commit = ScreenshotUploadRequests.commit(screenshotID: "s1", checksum: "abc")
        #expect(commit.method == .patch)
        #expect(commit.path == "/v1/appScreenshots/s1")
        let committed = try (json(commit)["data"] as? [String: Any])?["attributes"] as? [String: Any]
        #expect(committed?["uploaded"] as? Bool == true)
        #expect(committed?["sourceFileChecksum"] as? String == "abc")

        #expect(ScreenshotUploadRequests.delete(screenshotID: "s1") == PushRequest(method: .delete, path: "/v1/appScreenshots/s1", body: nil))

        let reorder = ScreenshotUploadRequests.reorder(setID: "set-1", screenshotIDs: ["b", "a"])
        #expect(reorder.path == "/v1/appScreenshotSets/set-1/relationships/appScreenshots")
        let ids = try (json(reorder)["data"] as? [[String: Any]])?.compactMap { $0["id"] as? String }
        #expect(ids == ["b", "a"])
        #expect(ScreenshotUploadRequests.statusPath(screenshotID: "s1").hasPrefix("/v1/appScreenshots/s1?"))
    }

    @Test func aReservationsOperationsComeInFileOrder() throws {
        let body = """
        {"data":{"type":"appScreenshots","id":"s9","attributes":{"fileName":"a.png","uploadOperations":[
        {"method":"PUT","url":"https://upload.example/2","offset":600,"length":400,"requestHeaders":[{"name":"Content-Type","value":"image/png"}]},
        {"method":"PUT","url":"https://upload.example/1","offset":0,"length":600}]}}}
        """
        let (id, operations) = try ScreenshotUploadRequests.reservation(in: Data(body.utf8))
        #expect(id == "s9")
        #expect(operations.map(\.offset) == [0, 600])
        let missing = Data(#"{"data":{"type":"appScreenshots","id":"s9","attributes":{}}}"#.utf8)
        #expect(throws: AppStoreConnectError.unexpectedPayload) { try ScreenshotUploadRequests.reservation(in: missing) }
    }

    @Test func theDeliveryStateSaysWhetherAppleCouldProcessIt() throws {
        let delivery = #"{"state":"FAILED","errors":[{"code":"IMAGE_TOOL_FAILURE"}]}"#
        let failed = Data(#"{"data":{"type":"appScreenshots","id":"s","attributes":{"assetDeliveryState":\#(delivery)}}}"#.utf8)
        let state = try #require(ScreenshotUploadRequests.deliveryState(in: failed))
        #expect(state.isFailed)
        #expect(state.errorCode == "IMAGE_TOOL_FAILURE")
        let complete = Data(#"{"data":{"type":"appScreenshots","id":"s","attributes":{"assetDeliveryState":{"state":"UPLOAD_COMPLETE"}}}}"#.utf8)
        #expect(ScreenshotUploadRequests.deliveryState(in: complete)?.isFailed == false)
    }

    @Test func anOperationSendsItsSliceWithItsHeaders() async throws {
        let transport = FakeHTTPTransport([CannedHTTPResponse(body: "")])
        let client = AppStoreConnectClient(credentials: TestKeys.credentials(), transport: transport)
        let operation = ScreenshotUploadOperation(
            method: "PUT", url: "https://upload.example/part/2", offset: 4, length: 3,
            requestHeaders: [ScreenshotUploadHeader(name: "Content-Type", value: "image/png")]
        )
        try await client.upload(operation, data: Data([0, 1, 2, 3, 4, 5, 6, 7, 8]))

        let request = try #require(transport.requests.first)
        #expect(request.httpMethod == "PUT")
        #expect(request.url?.absoluteString == "https://upload.example/part/2")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "image/png")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(request.httpBody == Data([4, 5, 6]))
    }

    @Test func aRefusedPartThrows() async {
        let transport = FakeHTTPTransport([CannedHTTPResponse(statusCode: 500, body: "")])
        let client = AppStoreConnectClient(credentials: TestKeys.credentials(), transport: transport)
        let operation = ScreenshotUploadOperation(method: "PUT", url: "https://upload.example/1", offset: 0, length: 1)
        await #expect(throws: AppStoreConnectError.self) { try await client.upload(operation, data: Data([1])) }
    }

    @Test func aSliceNeverRunsPastTheFile() {
        let operation = ScreenshotUploadOperation(method: "PUT", url: "u", offset: 3, length: 10)
        #expect(operation.slice(of: Data([0, 1, 2, 3, 4])) == Data([3, 4]))
    }
}
