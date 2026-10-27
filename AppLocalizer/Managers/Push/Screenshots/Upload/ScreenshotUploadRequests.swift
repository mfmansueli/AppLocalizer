//
//  ScreenshotUploadRequests.swift
//  AppLocalizer
//

import Foundation

/// The App Store Connect requests a screenshot push sends, and what it
/// reads from their responses. A set is created when the locale has none
/// for the display type; each image is reserved, uploaded in parts,
/// committed with its MD5 and checked; replaced ones are deleted; the set
/// is reordered last.
enum ScreenshotUploadRequests {
    /// `POST /v1/appScreenshotSets` for a version localization.
    static func createSet(displayType: ScreenshotDisplayType, localizationID: String) -> PushRequest {
        request(.post, "/v1/appScreenshotSets", [
            "data": [
                "type": "appScreenshotSets",
                "attributes": ["screenshotDisplayType": displayType.apiValue],
                "relationships": ["appStoreVersionLocalization": ["data": ["type": "appStoreVersionLocalizations", "id": localizationID]]],
            ],
        ])
    }

    /// `POST /v1/appScreenshots`: reserves an upload of `fileSize` bytes.
    static func reserve(fileName: String, fileSize: Int, setID: String) -> PushRequest {
        request(.post, "/v1/appScreenshots", [
            "data": [
                "type": "appScreenshots",
                "attributes": ["fileName": fileName, "fileSize": fileSize],
                "relationships": ["appScreenshotSet": ["data": ["type": "appScreenshotSets", "id": setID]]],
            ],
        ])
    }

    /// `PATCH /v1/appScreenshots/{id}`: every part is up; here's its MD5.
    static func commit(screenshotID: String, checksum: String) -> PushRequest {
        request(.patch, "/v1/appScreenshots/\(screenshotID)", [
            "data": [
                "type": "appScreenshots",
                "id": screenshotID,
                "attributes": ["uploaded": true, "sourceFileChecksum": checksum],
            ],
        ])
    }

    /// `GET` one screenshot's delivery state after the commit.
    static func statusPath(screenshotID: String) -> String {
        "/v1/appScreenshots/\(screenshotID)?fields%5BappScreenshots%5D=assetDeliveryState"
    }

    /// `DELETE /v1/appScreenshots/{id}`.
    static func delete(screenshotID: String) -> PushRequest {
        PushRequest(method: .delete, path: "/v1/appScreenshots/\(screenshotID)", body: nil)
    }

    /// `PATCH /v1/appScreenshotSets/{id}/relationships/appScreenshots`:
    /// the set's screenshots in this order.
    static func reorder(setID: String, screenshotIDs: [String]) -> PushRequest {
        request(.patch, "/v1/appScreenshotSets/\(setID)/relationships/appScreenshots", [
            "data": screenshotIDs.map { ["type": "appScreenshots", "id": $0] },
        ])
    }

    // MARK: - Responses

    /// The `data.id` of a created resource.
    static func createdID(in data: Data) throws -> String {
        try JSONDecoder().decode(ScreenshotAPISingleDocument<AppScreenshotUploadAttributes>.self, from: data).data.id
    }

    /// A reservation's screenshot ID and upload operations.
    static func reservation(in data: Data) throws -> (id: String, operations: [ScreenshotUploadOperation]) {
        let document = try JSONDecoder().decode(ScreenshotAPISingleDocument<AppScreenshotUploadAttributes>.self, from: data)
        let operations = document.data.attributes?.uploadOperations ?? []
        guard !operations.isEmpty else { throw AppStoreConnectError.unexpectedPayload }
        return (document.data.id, operations.sorted { $0.offset < $1.offset })
    }

    /// The delivery state in a screenshot's response, if it has one.
    static func deliveryState(in data: Data) -> ScreenshotDeliveryState? {
        let document = try? JSONDecoder().decode(ScreenshotAPISingleDocument<AppScreenshotUploadAttributes>.self, from: data)
        return document?.data.attributes?.assetDeliveryState
    }

    private static func request(_ method: PushRequest.Method, _ path: String, _ body: [String: Any]) -> PushRequest {
        let data = try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys, .withoutEscapingSlashes])
        return PushRequest(method: method, path: path, body: data)
    }
}
